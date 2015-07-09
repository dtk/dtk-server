require 'rubygems'
require 'json'
require 'readline'
require 'awesome_print'

class PerfLogParser
  def self.parse
    path = '/tmp/perf.out'
    results = []
    custom_results = []
    record = {}
    File.foreach(path) do |line|
      if field = get_field(line, /^OPERATION=(.+)/)
        results << record unless record.empty?
        record = {}
        record[:operation] = field
      elsif field = get_field(line, /^REQUEST_PARAMS=(.+)/)
        record[:request_params] = field
      elsif field = get_field(line, /^PERF_OPERATION_DUR=(.+)/)
        record[:perf_operation] = field
      elsif field = get_field(line, /^TABLE=(.+)/)
        record[:table] ||= []
        record[:table] << field
      elsif field = get_field(line, /^PERF_SQL=(.+)/)
        record[:perf_sql] ||= []
        record[:perf_sql] << field
      elsif field = get_field(line, /^SQL=(.+)/)
        record[:sql] ||= []
        record[:sql] << field
      elsif field = get_field(line, /^MEASUREMENT=(.+)/)

       # NEW KEY FOR AFTER DEMO elsif field = get_field(line, /^MEASUREMENT=(.+)/)
        k, v = field.split(',')[0..1]
        custom_results << { measurement: k, measurement_perf: v }
      end
    end
    [results, custom_results]
  end

  def self.get_field(line, regex)
    m = line.match(regex)
    m[1] if m
  end

  def self.get_results
    puts 'Parsing performance results...'
    results = {}
    custom_results = {}

    raw_results, custom_results_raw = parse()
    raw_results.each do |record|
      next unless record[:operation]

      total_dur = 0.0
      if record[:perf_sql]
        record[:perf_sql].each { |dur| total_dur += dur.to_f }
      end

      jsn = JSON.parse(record[:request_params])
      about = jsn['about']
      subtype = jsn['subtype']
      results_unique_key = "#{record[:operation]}#{about}#{subtype}"

      if results[results_unique_key]
        results[results_unique_key][:avg_tot_sql_dur] += total_dur
        results[results_unique_key][:table_list] += record[:table] if record[:table]
        results[results_unique_key][:avg_tot_oper_dur] += record[:perf_operation].to_f
        results[results_unique_key][:tr_cnt] += 1
      else
        results[results_unique_key] = {
          operation: record[:operation],
          assembly_subtype: subtype,
          about: about,
          db_call_cnt: record[:perf_sql] ? record[:perf_sql].size : 0,
          avg_tot_sql_dur: total_dur,
          avg_tot_oper_dur: record[:perf_operation].to_f,
          table_list: record[:table] || [],
          sql_list: record[:sql],
          sql_perf: record[:perf_sql],
          tr_cnt: 1
        }
      end
    end

    custom_results_raw.each do |record|
      unique_key = record[:measurement]
      if custom_results[unique_key]
        custom_results[unique_key][:avg_oper_dur] += record[:measurement_perf].to_f
        custom_results[unique_key][:tr_cnt] += 1
      else
        custom_results[unique_key] = {
          measurement: record[:measurement],
          avg_oper_dur: record[:measurement_perf].to_f,
          tr_cnt: 1
        }
      end
    end

    results.values.each do |record|
      record[:avg_tot_sql_dur] = get_avg(record[:avg_tot_sql_dur], record[:tr_cnt])
      record[:avg_tot_oper_dur] = get_avg(record[:avg_tot_oper_dur], record[:tr_cnt])
      record[:table_list] = record[:table_list].uniq.join(', ')
    end

    custom_results.values.each do |record|
      record[:avg_oper_dur] = get_avg(record[:avg_oper_dur], record[:tr_cnt])
    end

    puts 'Parsing done.'
    [results.values.sort { |a, b| a[:operation] <=> b[:operation] }, custom_results.values.sort { |a, b| a[:measurement] <=> b[:measurement] }]
  end

  def self.get_sql(results, operation, assembly, about)
    results.each do |record|
      if is_record_match(record, operation, assembly, about)
        puts "\n### OPERATION: #{operation}\n" if operation
        puts "### TYPE: #{assembly}\n" if assembly
        puts "### ABOUT: #{about}\n" if about
        puts "### QUERIES COUNT: #{record[:db_call_cnt]}\n\n"
        record[:sql_list].each_with_index do |e, i|
          puts "SQL QUERY: #{e}"
          puts "SQL DURATION: #{record[:sql_perf][i]}\n\n"
        end
        return
      end
    end
  end

   private

    def self.get_avg(tot, cnt)
      return tot if tot == 0
      ((tot / cnt) * 10.0).round() / 10.0
    end
    def self.is_record_match(record, operation, assembly, about)
      record[:operation] == operation && record[:assembly_subtype] == assembly && record[:about] == about
    end
end

class Print

  @@output_format_header = ['OPERATION', 'TYPE', 'ABOUT', 'OP_CNT', 'OP_AVG_DUR[ms]', 'DB_CALL_CNT', 'DB_AVG_DUR[ms]']
  @@output_format_custom_header = ['MEASUREMENT', 'INVOC_CNT', 'AVG_DUR[ms]']
  @@row_sep = "----------------------------------------------------------------------------------------------------------------------\n"

  def self.to_console(results, custom_results, regex = nil)
    output_format = " %-37s %-11s %-12s %-9s %-14s %-14s %s\n"
    output_format_custom = " %-29s %-15s %s\n"

    output = "\nPerformance results:\n\n"
    output += @@row_sep
    output += output_format % @@output_format_header
    output += @@row_sep

    results.each do |record|
      if regex.nil? || record[:operation].include?(regex)
        output += output_format % [record[:operation], record[:assembly_subtype], record[:about], record[:tr_cnt], record[:avg_tot_oper_dur], record[:db_call_cnt], record[:avg_tot_sql_dur]]
      end
    end
    output += @@row_sep
    output += "\n\n"
    output += @@row_sep
    output += output_format_custom % @@output_format_custom_header
    output += @@row_sep
    custom_results.each do |record|
      output += output_format_custom % [record[:measurement], record[:tr_cnt], record[:avg_oper_dur]]
    end
    output += @@row_sep
    puts "#{output}\n"
  end

  def self.to_csv(results, custom_results, path)
    path = '/tmp/perf_analysis_results.csv' unless path
    output = @@output_format_header.join(',') + "\n"
    results.each do |record|
      output += [record[:operation], record[:assembly_subtype], record[:about], record[:tr_cnt], record[:avg_tot_oper_dur], record[:db_call_cnt], record[:avg_tot_sql_dur]].join(',') + "\n"
    end

    output += "\n\n"

    output += @@output_format_custom_header.join(',') + "\n"
    custom_results.each do |record|
      output += [record[:measurement], record[:tr_cnt], record[:avg_oper_dur]].join(',') + "\n"
    end
    puts @@row_sep
    puts output
    puts @@row_sep

    File.open(path, 'w') { |file| file.write(output) }
  end
end

class CLI
  def self.start
    results, custom_results = PerfLogParser.get_results
    while line = Readline.readline('perf-tool> ', true)
      cmds = line.split(' ')
      case cmds[0]

      when 'exit'
        break

      when 'help'
        puts get_help()

      when 'parse'
        results, custom_results = PerfLogParser.get_results
        Print.to_console(results, custom_results)

      when 'print'
        Print.to_console(results, custom_results, cmds[1])

      when 'print_csv'
        Print.to_csv(results, custom_results, cmds[1])

      when 'get_sql'
        operation, assembly, about = cmds[1..3]
        puts '[ERROR] OPERATION parameter must be set. Check help for more details'; next unless operation
        PerfLogParser.get_sql(results, operation, assembly, about)

      else
        puts "\nUnknown command.\n\n"
      end
    end
  end

  def self.get_help
    output_format_custom = "\t%-37s %s\n"
    help = "\nHelp:\n\n"
    help += output_format_custom % ['exit', '']
    help += output_format_custom % ['get_sql OPERATION [TYPE] [ABOUT]', '- Returns SQL queries used in this operation']
    help += output_format_custom % ['parse', '- Parses performance output log']
    help += output_format_custom % ['print [REGEX]', '- Prints results to console']
    help += output_format_custom % ['print_csv [PATH]', '- Prints results to CSV file']
    help += "\n\n"
    help
  end
end

CLI.start
