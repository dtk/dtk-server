#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK
  #
  # Amar: Class that collects specific performance details and writes output to a file
  # 			Later on, file is parsed and various performance stats are collected
  #
  class PerformanceService
    # Configuration
    @@file_path = "#{R8::Config[:performance_log][:path]}/perf_#{Common::Aux.running_process_user()}.out" 
    @@perf_enabled = R8::Config[:performance_log][:enable]

    @@timer_hash = {}
    @@measure_lock = Mutex.new
    @@file_lock = Mutex.new

    # Logs performance related line into performance output file
    # Each line is predifined and reused in parsing output tool
    # For new lines, tool must be altered
    def self.log(line)
      return unless @@perf_enabled
      @@file_lock.synchronize { File.open(@@file_path, 'a') { |file| file.write(line + "\n") } }
    end

    # Starts timer for provided measure
    # If called from multithreaded part, i.e. ruote, unique key must be provided to measure multiple measurements
    # I've used self.object_id successfully for unique_key
    def self.start(measure, unique_key = nil)
      return unless @@perf_enabled
      push_time_now(measure, unique_key)
    end

    # This method ends custom measurements that in order to work must be applied specifically in parsing tool
    # Ends timer for provided measure and logs the measurement in performance output file
    # If called from multithreaded part, i.e. ruote, unique key must be provided to measure multiple measurements
    # I've used self.object_id successfully for unique_key
    def self.end(measure, unique_key = nil)
      return unless @@perf_enabled
      duration = duration_to_now(pop_time(measure, unique_key))
      log("#{measure}=#{duration}")
    end

    # This method ends generic measurements that are being logged with format 'MEASUREMENT=#{measure},#{duration}'
    # Ends timer for provided measure and logs the measurement in performance output file
    # If called from multithreaded part, i.e. ruote, unique key must be provided to measure multiple measurements
    # I've used self.object_id successfully for unique_key
    def self.end_measurement(measure, unique_key = nil)
      return unless @@perf_enabled
      duration = duration_to_now(pop_time(measure, unique_key))
      log("MEASUREMENT=#{measure},#{duration}") if duration
    end

    private

    def self.push_time_now(measure, unique_key)
      @@measure_lock.synchronize { @@timer_hash["#{measure}#{unique_key}"] = Time.now }
    end
    def self.pop_time(measure, unique_key)
      @@measure_lock.synchronize { @@timer_hash.delete("#{measure}#{unique_key}") }
    end
    def self.duration_to_now(beg_time = nil)
      beg_time ? (Time.now - beg_time) : 'UNKNOWN'
    end
  end
end