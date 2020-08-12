Puppet::Type.newtype(:accessrule) do

    @doc = %q{
        Create an entry in access.conf.

        Each resource has a name that (must) start with a number. The number determines
        the order of the entries in access.conf.
        `pam_access` uses the first matching entry, so the order is important.

        Each parameter corresponds to a field in [access.conf](https://linux.die.net/man/5/access.conf).
        A parameter can take any value the field allows (including @netgroup, @netgroup@@netgroup and EXCEPT clauses).

        The _who_ and _origin_ parameters must be a list of strings. EXCEPT clauses must be provided as a single string,
        but should come last as everything after an EXCEPT in access.conf is considered as part of that clause.
    }

    ensurable

    newparam(:name) do
        desc "Rule name. Must exist of a number, a space and a name. The number determines the order in the access.conf file. The name can be anything you want. The order between rules with the same number can change."

        isnamevar

        newvalues(%r{^\d+[[:graph:][:space:]]+$})
    end

    newproperty(:permission) do

        desc "Permission. Either + (allow) or - (deny)."

        defaultto '-'
        newvalues('+', '-')
    end

    newproperty(:who, :array_matching => :all) do

        desc "users/groups field. Must be a list of strings. All valid access.conf values are accepted."

    end

    newproperty(:origin, :array_matching => :all) do

        desc "origins field. Must be a list of strings. All valid access.conf values are accepted."

    end

end