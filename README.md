# 104 Worktime Export Plugin

Export Redmine time entries in [104 Human Resource](https://www.104.com.tw/) system format for Taiwan companies.

## Features

- Adds "104 Worktime Report" tab to Spent Time page
- Groups time entries by date and user
- Automatically calculates break time (adds 1 hour if daily hours > 4)
- Exports Excel file compatible with 104 HR system import
- Supports both global and project-scoped time entries
- Filters show only active users

## Requirements

- Redmine 5.0+ or RedMica
- Ruby 3.0+

## Installation

1. Clone or copy this plugin to your Redmine plugins directory:

```bash
cd /path/to/redmine/plugins
git clone <repository_url> one_zero_four_worktime_export
```

2. Install dependencies:

```bash
bundle install
```

3. Restart Redmine

## Configuration

1. Go to **Administration → Plugins → 104 Worktime Export → Configure**

2. Set the following options:

| Setting | Description |
|---------|-------------|
| Employee Number Custom Field | Select a User custom field that contains the 104 employee number |
| Default Start Time | Default work start time (format: HH:MM, default: 09:30) |

3. Go to **Administration → Roles and permissions**

4. Enable **Export 104 Worktime** permission for roles that need access

## Usage

1. Navigate to **Spent Time** (global or within a project)

2. Click the **104 Worktime Report** tab

3. Set date filters as needed (defaults to last month)

4. Click **Export 104 Worktime** to download Excel file

## Excel Output Format

The exported Excel file contains the following columns:

| Column | Description | Format |
|--------|-------------|--------|
| 序號 | Row number | Integer |
| 員工編號 | Employee number | From custom field |
| 員工姓名 | Employee name | User's display name |
| 時數開始日期 | Start date | YYYY/MM/DD |
| 時數開始時間 | Start time | HH:MM |
| 時數結束日期 | End date | YYYY/MM/DD |
| 時數結束時間 | End time | HH:MM (calculated) |
| 是否扣除休息時間 | Deduct break | 是/否 |

### Break Time Calculation

- If total hours for a day > 4 hours: adds 1 hour break time, marks "是"
- If total hours for a day ≤ 4 hours: no break time added, marks "否"

## License

This plugin is released under the MIT License.

## Author

[5xRuby CO., LTD](https://5xruby.com/en)
