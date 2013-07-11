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

require 'test_helper'

module Seahorse
  class Client
    describe Handler do

      def context
        @context ||= Context.new
      end

      def response
        @response ||= Response.new
      end

      def config
        @config ||= Configuration.new
      end

      it 'is constructed with a configuration object' do
        Handler.new(config).config.must_be_same_as(config)
      end

      it 'can be constructed with another handler' do
        handler = Handler.new(config)
        Handler.new(config, handler).handler.must_be_same_as(handler)
      end

      it 'responds to #call' do
        Handler.new(config).must_respond_to(:call)
      end

      it 'chains #call to the nested handler' do
        handler = Minitest::Mock.new
        handler.expect(:call, response, [context])
        Handler.new(config, handler).call(context)
        assert handler.verify
      end

      it 'returns the response from the nested handler' do
        handler = Minitest::Mock.new
        handler.expect(:call, response, [context])
        Handler.new(config, handler)
          .call(context)
          .must_be_same_as(response)
      end

    end
  end
end
