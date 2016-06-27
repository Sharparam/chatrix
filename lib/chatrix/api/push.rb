module Chatrix
  module Api
    # Contains methods for accessing the "push" endpoints on the server.
    #
    # Refer to the official documentation for more information about these.
    class Push < ApiComponent
      # Get all active pushers for the current user.
      # @return [Hash] A list of pushers for the user.
      def pushers
        make_request(:get, '/pushers').parsed_response
      end

      # Add, remove, or modify pushers for the current user.
      # @param pusher [Hash] Pusher information.
      # @return [Boolean] `true` if the operation was carried out successfully,
      #   otherwise `false`.
      def modify_pusher(pusher)
        make_request(:post, '/pushers/set', content: pusher).code == 200
      end

      # Gets all the push rules defined for this user, optionally limited
      # to a specific scope.
      # @param scope [String,nil] If set, only rules within that scope will
      #   be returned.
      # @return [Hash] A list of push rules for the user.
      def get_rules(scope = nil)
        path = scope ? "/pushrules/#{scope}" : '/pushrules'
        make_request(:get, path).parsed_response
      end

      # Gets a specific rule.
      #
      # @param scope [String] The scope to access.
      # @param kind [String] The kind of rule.
      # @param id [String] The rule to get.
      # @return [Hash] Details about the rule.
      def get_rule(scope, kind, id)
        make_request(:get, "/pushrules/#{scope}/#{kind}/#{id}").parsed_response
      end

      # Deletes a push rule.
      #
      # @param (see #get_rule)
      # @param id [String] The rule ID to delete.
      # @return [Boolean] `true` if the rule was deleted successfully,
      #   otherwise `false`.
      def delete_rule(scope, kind, id)
        make_request(:delete, "/pushrules/#{scope}/#{kind}/#{id}").code == 200
      end

      # Adds or change a push rule.
      #
      # @param (see #get_rule)
      # @param id [String] The rule to add or change.
      # @param opts [Hash{Symbol => String}] Additional options to pass in
      #   the query string. Note that only one of the options should be set.
      #
      # @option opts [String] :before Add this rule as the next-most
      #   important rule with respect to the rule specified here.
      # @option opts [String] :after Add this rule as the next-less
      #   important rule with respect to the rule specified here.
      #
      # @return [Boolean] `true` if the operation was carried out successfully,
      #   otherwise `false`.
      def add_rule(scope, kind, id, rule, opts = {})
        path = "/pushrules/#{scope}/#{kind}/#{id}"
        make_request(:put, path, params: opts, content: rule).code == 200
      end

      # Sets or modifies the actions for a rule.
      #
      # @param (see #get_rule)
      # @param id [String] The rule ID to modify actions for.
      # @param actions [Hash] Actions to perform when the conditions for
      #   this rule are met.
      # @return [Boolean] `true` if the actions were modified successfully,
      #   otherwise `false`.
      def set_actions(scope, kind, id, actions)
        path = "/pushrules/#{scope}/#{kind}/#{id}/actions"
        make_request(:put, path, content: actions).code == 200
      end

      # Sets the enabled state of a rule, the default is to enable it.
      #
      # @param (see #get_rule)
      # @param id [String] The rule ID to modify the enable state for.
      # @param enabled [Boolean] Whether to enable or disable the rule.
      # @return [Boolean] `true` if the state was modified successfully,
      #   otherwise `false`.
      def enable(scope, kind, id, enabled = true)
        path = "/pushrules/#{scope}/#{kind}/#{id}/actions"
        make_request(:put, path, content: { enabled: enabled }).code == 200
      end

      # Disable a push rule.
      # This is essentially an alias for #enable with the last parameter
      # as `false`.
      #
      # @param (see #get_rule)
      # @param id [String] The rule ID to disable.
      # @return [Boolean] `true` if the rule was disabled, otherwise `false`.
      def disable(scope, kind, id)
        enable(scope, kind, id, false)
      end
    end
  end
end
