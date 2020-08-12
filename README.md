# access

#### Table of Contents
1. [Module Description](#module-description)
1. [Setup](#setup)
   * [What access affects](#what-access-affects)
   * [Beginning with access](#beginning-with-access)
1. [Usage](#usage)
1. [Limitations](#limitations)
1. [Development](#development)

## Module description
Configure entries in access.conf.

## Setup
### What access affects
By default, the module will purge all unmanaged rules (this includes comments). If you do not want this to happen, set the `$purge` parameter to `false`.

Comments are considered as rules, so the resulting file will not have any comments.

### Beginning with access

Including the main `access` class is recommended but is not required.

```
include access
```

Rules are generated with `accessrule`.
```
accessrule {'400 ALLOW ADMINS':
    permission => '+',
    who        => [
        '@ADMINS'
    ],
    origin     => [
        'ALL'
    ],
}
```

## Usage
If you wish to purge all non-managed access rules, you have to include the `access` class. Otherwise, this is optional (but you must set `$purge` to `false` to prevent purging of unmaaged rules).

Each `accessrule` resource must have a name like _number_ _description_. The number determines the order in the access.conf file. Lower numbers go first, and `pam_access` uses the first matching line to decide whether or not to give access.

Comments are always removed, even when `$purge` is set to `false`.

### Without purging
```
class {'access':
    purge => false
}
```

All existing rules are converted to `9999 <hash of the rule>`. If your access rules must come before that, give them a name with a lower number. Otherwise, a higher one. It is not possible to insert them inbetween.

```
accessrule {'10000 DENY ALL':
    permission => '-',
    who        => [
        'ALL'
    ],
    origin     => [
        'ALL'
    ],
}
```

### With purging

```
include access
```

The number in the name of the resource determines the order in which they appear in the file. Between resources with the same number, the order can't be guaranteed. If two resources must be in a specific order, it is recommended to give them a different number.

```
accessrule {'200 ALLOW ADMINS':
    permission => '+',
    who        => [
        '@Admins'
    ],
    origin     => [
        'jumpserver1',
        'jumpserver2'
    ]
}

accessrule {'999 DENY ALL':
    permission => '-',
    who        => [
        'ALL'
    ],
    origin     => [
        'ALL'
    ],
}
```

## Limitations
This module can't handle comments; they are removed if they are encountered, even if you set `$purge` to `false`.

The order of rules with the same number is not guaranteed (but usually does not change).

## Development
Submit pull requests for new features or bugfixes on our [Github repository](https://github.com/InfrabelLinux/puppet-access).