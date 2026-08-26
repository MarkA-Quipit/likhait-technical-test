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

This drift risk showed up concretely during final testing: after removing the dead `payer_name` column from `init.sql`'s `CREATE TABLE expenses` statement, a full volume rebuild (`docker compose down -v && docker compose up --build`) failed on `RemovePayerNameFromExpenses` with `Can't DROP 'payer_name'; check that column/key exists`. The migration assumed a `payer_name` column that a fresh `init.sql` no longer creates. Fixed with a `column_exists?` guard so the migration is a safe no-op against a fresh DB and still works against a legacy one. Small fix, but a direct example of why having schema defined in two places is fragile.

### 5. Missing app timezone allowed false-positive future-date rejection

BONUS-001's `Expense#date_not_in_future` validation uses `date.future?`, which under the hood compares against `Date.current`. `Date.current` resolves to `Time.zone.today` once a Rails app timezone is set, but `config/application.rb` had `config.time_zone` commented out, so Rails defaulted to UTC. For a same-day expense submitted from UTC+8, this meant a real 8-hour window each day (roughly midnight to 8am local time) where the backend's "today" was still the previous day in UTC, so a legitimate today-dated expense got rejected with `"Date can't be in the future"`.

This was flagged as an open, unfixed edge case in the original `PR-BONUS-001-prevent-future-dates.md` description ("a theoretical client/server timezone mismatch on 'today'") and turned up as a real, reproducible bug during final testing. Fixed by setting `config.time_zone = "Asia/Manila"` in `application.rb`, so `Date.current` matches the app's actual operating timezone instead of defaulting to UTC.

### 6. Category name has no length validation

The schema caps `name` at `limit: 100`, but the model only validates presence and uniqueness. A name over 100 characters doesn't fail cleanly with a 422, it hits the DB constraint directly and throws `ActiveRecord::ValueTooLong`, which comes back as a 500 instead of a normal validation error. Small fix (`length: { maximum: 100 }`), just didn't make it into FEATURE-001.

### 7. No category edit or delete

FEATURE-001 only asked for category creation ("Backend endpoint to persist the new category... Updated category list after creation"), so that's all I built. But it's worth noting the gap: there's currently no way to rename or remove a category once created, including a mis-typed or duplicate-but-differently-cased one that slipped past the uniqueness check before normalization was added.

Delete in particular needs more thought than it looks like at first glance. The current association is:

```ruby
class Category < ApplicationRecord
  has_many :expenses, dependent: :destroy
end
```

`dependent: :destroy` means deleting a category currently cascades to deleting every expense tied to it, silently, with no confirmation step or count shown to the user. A real "delete category" feature would need to either block deletion when expenses are attached (safer default) or make the cascade explicit and confirmed in the UI, not the current dependent behavior. Flagging this rather than building it, since it's new scope beyond the ticket.
