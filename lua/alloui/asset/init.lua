local Asset = require 'alloui.asset.asset'

Asset.Manager = require 'alloui.asset.asset_manager'
Asset.Cache = require 'alloui.asset.asset_cache'
if lovr then 
    Asset.DiskCache = require 'alloui.asset.asset_disk_cache'
    Asset.LovrFile = require 'alloui.asset.lovr_file_asset'
end
Asset.Base64 = require 'alloui.asset.base64_asset'
Asset.File = require 'alloui.asset.file_asset'
Asset.View = require 'alloui.asset.asset_view'

return Asset
