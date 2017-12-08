# frozen_string_literal: true

module Fluent
  module GelfPluginUtil
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    def make_gelfentry(tag, time, record)
      gelfentry = {}
      gelfentry["timestamp"] = if defined?(Fluent::EventTime) && time.is_a?(Fluent::EventTime)
                                 time.sec + (time.nsec.to_f / 1_000_000_000).round(3)
                               else
                                 time
                               end

      gelfentry["_fluentd_tag"] = tag

      record.each_pair do |k, v|
        case k
        when "timestamp" then gelfentry["timestamp"] = v
        when "msec" then
          if time.is_a?(Integer) && record["timestamp"].nil?
            gelfentry["timestamp"] = "#{time}.#{v}".to_f
          else
            gelfentry["_msec"] = v
          end
        when "source_realtime_timestamp" then gelfentry["timestamp"] = (v.to_f / 1_000_000).round(3)
        when "host", "hostname" then gelfentry["host"] = v.to_s
        when "priority" then gelfentry["level"] = v.to_i
        when "syslog_facility" then gelfentry["facility"] = SYSLOG_FACILITY[v]
        when "short_message", "version", "full_message", "facility", "file", "line", "level" then gelfentry[k] = v
        else
          k.to_s.start_with?("_") ? gelfentry[k] = v : gelfentry["_#{k}"] = v
        end
      end

      if gelfentry["short_message"].nil? || gelfentry["short_message"].to_s.empty?
        gelfentry["short_message"] = if gelfentry.key?("_message") && !gelfentry["_message"].to_s.empty?
                                       gelfentry.delete("_message")
                                     elsif gelfentry.key?("_log") && !gelfentry["_log"].to_s.empty?
                                       gelfentry.delete("_log")
                                     else
                                       "(no message)"
                                     end
      else
        gelfentry.delete("_log")
      end

      if gelfentry["level"].nil?
        level = LEVEL_MAPPING.keys.select { |k| tag =~ /\.#{k}/ }.first
        gelfentry["level"] = LEVEL_MAPPING[level] if level
      end

      gelfentry.to_msgpack
    end
  end
end
