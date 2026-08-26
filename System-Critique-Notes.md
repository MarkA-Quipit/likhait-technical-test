# System Critique Notes

After reviewing the entire codebase (models, controllers, schema, frontend API layer, and docker-compose setup), here are a few things I noticed but didn't fix directly, either because they were outside the scope of the tickets or better suited to a written note than a PR.

---

## Security

### 1. Hardcoded secrets in docker-compose.yml

```yaml
MYSQL_ROOT_PASSWORD: rootpassword
MYSQL_PASSWORD: expense_password
```

These are committed in plaintext, and since the fork has to be public, anyone who clones it sees real-looking credentials. Low risk since it's just local dev infra, but the cleaner setup would be a `.env` file (gitignored) with a `.env.example` committed instead.

### 2. No authentication anywhere

There's no `before_action` auth check or user scoping on any endpoint. Every expense and category is globally readable and writable, and there's no user model at all. The tickets never asked for auth, so I didn't add it, but it's worth stating outright: this is a single-tenant app with fully shared data by design.

---

## Architectural / Data Integrity

### 3. No pagination on the expenses index

```ruby
expenses = Expense.includes(:category).order(date: :desc, created_at: :desc)
...
render json: expenses.map { |expense| format_expense(expense) }
```

The seed data generates close to 4,300 expenses, and this loads and serializes all of them every time, even though `CalendarExpenseTable.tsx` only paginates on the client side after the fact. Not a problem at this data size, but the frontend pagination component suggests this was meant to be paginated from the start.

### 4. init.sql and Rails migrations as two sources of schema truth

`init.sql` handles container-level DB/user setup, but table schema also lives in the migrations, and the two have drifted before (the `date` column mix-up, the `payer_name` cleanup). I already patched `init.sql` directly to fix the missing test DB grants, but a cleaner long-term fix would be to strip schema creation out of `init.sql` entirely and let migrations be the only source of truth for table structure.

### 5. Category name has no length validation

The schema caps `name` at `limit: 100`, but the model only validates presence and uniqueness. A name over 100 characters doesn't fail cleanly with a 422, it hits the DB constraint directly and throws `ActiveRecord::ValueTooLong`, which comes back as a 500 instead of a normal validation error. Small fix (`length: { maximum: 100 }`), just didn't make it into FEATURE-001.
