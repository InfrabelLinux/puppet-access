##
#  @summary Purge (or not purge) unmanaged access.conf entries.
#
# @example Basic usage
#  class {'access':
#     purge => false,
#  }
#
# @param purge
#   Purge unmanaged entries. Default is `true`.
# @param rules
#   Create a set of default rules by providing a create_resources-hash full of accessrules.
class access (
  Hash $rules,
  Boolean $purge = true
) {
  ##
  # Default rules
  ##
  resources {'accessrule':
    purge => $purge
  }

  create_resources(accessrule, $rules)

}
