# frozen_string_literal: true

require "fluent/plugin/output"
require "fluent/plugin/gelf_plugin_util"

module Fluent
  module Plugin
    class GelfOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output("gelf", self)

      include Fluent::GelfPluginUtil

      config_param :host, :string, default: nil
      config_param :port, :integer, default: 12_201

      def configure(conf)
        super
        raise ConfigError, "'host' parameter is required" unless conf.key?("host")
      end

      def start
        super
      end

      def shutdown
        super
      end

      def format(tag, time, record)
        make_gelfentry(tag, time, record).to_msgpack
      end

      def write(chunk) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        records = []
        chunk.msgpack_each do |record|
          records.push JSON.dump(record) + "\0" # Message delimited by null char
        end

        log.debug "establishing connection with GrayLog"
        socket = TCPSocket.new(@host, @port)

        begin
          log.debug "sending #{records.count} records in batch"
          socket.write(records.join)
        ensure
          log.debug "closing connection with GrayLog"
          socket.close
        end
      end

      def formatted_to_msgpack_binary
        true
      end

      def multi_workers_ready?
        true
      end
    end
  end
end
