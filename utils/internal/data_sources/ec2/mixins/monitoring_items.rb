module XYZ
  module DSNormalizer
    class Ec2
      module MonitoringItemsClassMixin
        def default_node_monitoring_items
          DefaultChecks.inject(DBUpdateHash.new){|h,o|h.merge(o[:display_name] => o)}
        end
        DefaultChecks =
          [
           {description: 'ping',
           display_name: 'check_ping',
           enabled: true
          },

           {description: 'Free Space All Disks',
            display_name: 'check_all_disks',
            enabled: true
          },
           {description: 'Free Memory',
            display_name: 'check_mem',
            enabled: true
          },

           {description: 'Iostat',
            display_name: 'check_iostat',
            enabled: true
          },
           {description: 'Memory Profiler',
            display_name: 'check_memory_profiler',
            enabled: true
         },
           {description: 'SSH',
            display_name: 'check_ssh',
            enabled: true
          },
           {description: 'Processes',
            display_name: 'check_local_procs',
            enabled: true
          }
          ]
      end
    end
  end
end
