# frozen_string_literal: true

require_relative '../test_helper'

class ExcelExporterTest < ActiveSupport::TestCase
  fixtures :users

  def test_generate_with_entries
    user = User.find(2)
    entries = [
      {
        date: Date.new(2024, 1, 15),
        user: user,
        total_hours: 8.0,
        adjusted_hours: 9.0,
        deduct_break: true
      },
      {
        date: Date.new(2024, 1, 16),
        user: user,
        total_hours: 3.5,
        adjusted_hours: 3.5,
        deduct_break: false
      }
    ]

    settings = {
      'employee_number_cf_id' => '',
      'default_start_time' => '09:30'
    }

    exporter = OneZeroFourWorktime::ExcelExporter.new(entries, settings)
    package = exporter.generate

    assert_kind_of Axlsx::Package, package
    assert_equal 1, package.workbook.worksheets.count
    assert_equal '104工時報表', package.workbook.worksheets.first.name

    # Verify row count: 4 header rows + 2 data rows
    assert_equal 6, package.workbook.worksheets.first.rows.count
  end

  def test_calculate_end_time
    exporter = OneZeroFourWorktime::ExcelExporter.new([], {})

    # Test basic calculation
    end_time = exporter.send(:calculate_end_time, '09:30', 8)
    assert_equal '17:30', end_time

    # Test with break time
    end_time = exporter.send(:calculate_end_time, '09:30', 9)
    assert_equal '18:30', end_time

    # Test edge case
    end_time = exporter.send(:calculate_end_time, '09:30', 3.5)
    assert_equal '13:00', end_time
  end
end
