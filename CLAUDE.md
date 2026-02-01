# CLAUDE.md

## Plugin Overview

This is a Redmine/RedMica plugin that exports time entries in 104 HR system format (Taiwan's 104 Human Resource platform).

## Directory Structure

```
one_zero_four_worktime_export/
├── init.rb                     # Plugin registration
├── Gemfile                     # Dependencies (caxlsx)
├── config/
│   ├── routes.rb               # URL routes
│   └── locales/                # i18n translations (en, zh-TW)
├── app/
│   ├── controllers/
│   │   └── one_zero_four_worktime_controller.rb
│   ├── views/
│   │   ├── one_zero_four_worktime/
│   │   │   └── index.html.erb
│   │   ├── timelog/
│   │   │   └── _date_range.html.erb  # Override to add tab
│   │   └── settings/
│   │       └── _one_zero_four_worktime_settings.html.erb
│   └── helpers/
│       └── one_zero_four_worktime_helper.rb
├── lib/
│   └── one_zero_four_worktime/
│       └── excel_exporter.rb   # Excel generation
└── test/
    ├── functional/
    │   └── one_zero_four_worktime_controller_test.rb
    └── unit/
        └── excel_exporter_test.rb
```

## Key Components

### Controller (`one_zero_four_worktime_controller.rb`)
- `index`: Display preview with date filter (redirects to last month if no filter)
- `export`: Generate and download Excel file
- Uses `TimeEntryQuery` for filtering, overrides user filter to show only active users

### Excel Exporter (`lib/one_zero_four_worktime/excel_exporter.rb`)
- Generates 104 HR format Excel with headers: 序號, 員工編號, 員工姓名, 時數開始日期, 時數開始時間, 時數結束日期, 時數結束時間, 是否扣除休息時間
- Adds 1 hour break time if daily hours > 4

### Routes
- Global: `/report_104_worktime`
- Project: `/projects/:project_id/report_104_worktime`

## Testing

```bash
# Run all plugin tests
RAILS_ENV=test bundle exec rake test TEST="plugins/one_zero_four_worktime_export/test/**/*_test.rb"

# Run specific test file
RAILS_ENV=test bundle exec ruby plugins/one_zero_four_worktime_export/test/functional/one_zero_four_worktime_controller_test.rb
```

## Configuration

Plugin settings (Administration → Plugins → 104 Worktime Export → Configure):
- `employee_number_cf_id`: User custom field ID for 104 employee number
- `default_start_time`: Default work start time (default: 09:30)

## Permission

- `export_104_worktime`: Required to access the 104 Worktime Report tab and export
