module DTK
	# 
	# Amar: Class that collects specific performance details and writes output to a file
	# 			Later on, file is parsed and various performance stats are collected
	#
	class PerformanceService

		# Configuration
		@@file_path = "/tmp/perf.out"
		@@perf_enabled = true


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
		def self.start(measure, unique_key=nil)
			return unless @@perf_enabled
			@@measure_lock.synchronize { @@timer_hash["#{measure}#{unique_key}"] = Time.now }
		end

		# This method ends custom measurements that in order to work must be applied specifically in parsing tool
		# Ends timer for provided measure and logs the measurement in performance output file
		# If called from multithreaded part, i.e. ruote, unique key must be provided to measure multiple measurements
		# I've used self.object_id successfully for unique_key
		def self.end(measure, unique_key=nil)
			return unless @@perf_enabled
			duration = 0
			@@measure_lock.synchronize { duration = (Time.now - (@@timer_hash.delete("#{measure}#{unique_key}") || 0)) * 1000 }
			log("#{measure}=#{duration}")
		end

		# This method ends generic measurements that are being logged with format 'MEASUREMENT=#{measure},#{duration}'
		# Ends timer for provided measure and logs the measurement in performance output file
		# If called from multithreaded part, i.e. ruote, unique key must be provided to measure multiple measurements
		# I've used self.object_id successfully for unique_key
		def self.end_measurement(measure, unique_key=nil)
			return unless @@perf_enabled
			duration = 0
			@@measure_lock.synchronize { duration = (Time.now - (@@timer_hash.delete("#{measure}#{unique_key}") || 0)) * 1000 }
			log("MEASUREMENT=#{measure},#{duration}")
		end

	end
end
