# Copyright 2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

module Seahorse
  class Client

    autoload :Configuration, 'seahorse/client/configuration'
    autoload :Context, 'seahorse/client/context'
    autoload :Endpoint, 'seahorse/client/endpoint'
    autoload :EventEmitter, 'seahorse/client/event_emitter'
    autoload :Handler, 'seahorse/client/handler'
    autoload :HeaderHash, 'seahorse/client/header_hash'
    autoload :HttpHandler, 'seahorse/client/http_handler'
    autoload :PluginList, 'seahorse/client/plugin_list'
    autoload :Request, 'seahorse/client/request'
    autoload :Response, 'seahorse/client/response'
    autoload :VERSION, 'seahorse/client/version'

    @plugins = PluginList.new

    # @option options [String, URI::HTTP, URI::HTTPS, Endpoint] :endpoint
    #   Endpoints specify the http scheme, hostname and port to connect
    #   to.  You must specify at a minimum the hostname.  Endpoints without
    #   a uri scheme will default to https on port 443.
    #
    #       # defaults to https on port 443
    #       hostname: 'domain.com'
    #
    #       # defaults to http on port 80
    #       hostname: 'domain.com', ssl_default: false
    #
    #       # defaults are ignored, as scheme and port are present
    #       hostname: 'http://domain.com:123'
    #
    # @option options [Boolean] :ssl_default (true) Specifies the default
    #   scheme for the #endpoint when not specified.  Defaults to `true`
    #   which creates https endpoints.
    #
    # @option options [Handler] :http_handler (HttpHandler.new)
    #
    def initialize(options = {})
      @config = build_config(options)
      @endpoint = build_endpoint(options)
      @handler = options[:http_handler] || HttpHandler.new(@config)
    end

    # @return [Endpoint]
    attr_reader :endpoint

    # @return [Configuration]
    attr_reader :config

    # Builds and returns a {Request} for the named operation.  The request
    # will not have been sent.
    # @param [Symbol, String] operation_name
    # @return [Request]
    def build_request(operation_name, params = {})
      Request.new(nil, context_for(operation_name, params))
    end

    private

    # @return [Context]
    def context_for(operation_name, params)
      Context.new(
        operation_name: operation_name.to_s,
        params: params,
        config: config,
        endpoint: endpoint)
    end

    # @param [Hash] options
    def build_config(options)
      Configuration.new(options)
    end

    # @option options [:endpoint] The preferred endpoint.  When not set,
    #   the endpoint will default to the value set in the API.
    # @return [Endpoint]
    def build_endpoint(options)
      endpoint = options[:endpoint] || default_endpoint
      Endpoint.new(endpoint, ssl_default: config.ssl_default)
    end

    # @return [String] Returns the default endpoint for the client.
    def default_endpoint
      api['endpoint']
    end

    # @return [Hash]
    def api
      self.class.api
    end

    class << self

      # Registers a plugin with this client.
      #
      # @example Register a plugin
      #
      #   ClientClass.add_plugin(PluginClass)
      #
      # @example Register a plugin by name
      #
      #   ClientClass.add_plugin('gem-name.PluginClass')
      #
      # @example Register a plugin with an object
      #
      #   plugin = MyPluginClass.new(options)
      #   ClientClass.add_plugin(plugin)
      #
      # @param [Class, Symbol, String, Object] plugin
      # @see .remove_plugin
      # @see .plugins
      # @return [Class, Object] Returns the loaded plugin.
      def add_plugin(plugin)
        @plugins.add(plugin)
      end

      # @see .add_plugin
      # @see .plugins
      # @return [Class, Object] Returns the removed plugin.
      def remove_plugin(plugin)
        @plugins.remove(plugin)
      end

      # Returns the list of registered plugins for this Client.  Plugins are
      # inherited from the client super class when the client is defined.
      # @see .add_plugin
      # @see .remove_plugin
      # @return [Array]
      def plugins
        Array(@plugins).freeze
      end

      # @param [Hash] api
      # @return [Class]
      def define(api)
        client_class = Class.new(Client)
        client_class.set_api(api)
        client_class
      end

      # @return [Hash]
      def api
        @api
      end

      # @param [Hash] api
      def set_api(api)
        @api = api
      end

      private

      def inherited(subclass)
        subclass.instance_variable_set('@plugins', PluginList.new(@plugins))
      end

    end

  end
end
