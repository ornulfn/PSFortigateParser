# PSFortigateParser

# Introduction

The purpose of this Powershell module is to parse a Fortigate configuration file and create CSV reports.

CSV files are created with delimiter specified by system regional settings and will be saved using same encoding as specified for reading the config file. To open created CSV files in Excel, save files using .csv extension - double click on file to open it in Excel (Excel import wizard does not correctly parse multivalued cells using linefeed as separator).

## Changelog

Detailed changes for each release are documented in the [release notes](https://github.com/ornulfn/PSFortigateParser/releases).

## Quickstart

Basic usage:

```powershell
    # Open and parse a Fortigate config file using UTF8 encoding, save reports as CSV.
    $Config = New-PSFortigateReport -Params @('C:\firewall.conf', [System.Text.Encoding]::UTF8)
    $Config.savePolicyReport('C:\firewall-policy.csv')
    $Config.saveAddressReport('C:\firewall-address.csv')
    $Config.saveAddressGroupReport('C:\firewall-addressgroup.csv')
    $Config.saveServiceReport('C:\firewall-service.csv')
    $Config.saveServiceGroupReport('C:\firewall-servicegroup.csv')
```
