--[[
Get Image Size
By: MikuAuahDark (https://sites.google.com/site/nullauahdark/getimagewidthheight)
Allows you to get image/video size from most files.
Supported Image/Video Files(by priority order):
1. Portable Network Graphics
2. Windows Bitmap
3. JPEG
4. GIF
5. Photoshop Document
6. Truevision TGA
7. JPEG XR/TIFF*
8. MP4
9. AVI
(*) = experimental
]]

local function GetImageWidthHeight(file)

  print("running GetImageWidthHeight")

	local fileinfo=type(file)
	if type(file)=="string" then
		file=assert(io.open(file,"rb"))
	else
		fileinfo=file:seek("cur")
	end
	local function refresh()
		if type(fileinfo)=="number" then
			file:seek("set",fileinfo)
		else
			file:close()
		end
	end
	local width,height=0,0
	file:seek("set",1)
	-- Detect if PNG
	if file:read(3)=="PNG" then
		--[[
			The strategy is
			1. Seek to position 0x10
			2. Get value in big-endian order
		]]
		file:seek("set",16)
		local widthstr,heightstr=file:read(4),file:read(4)
		if type(fileinfo)=="number" then
			file:seek("set",fileinfo)
		else
			file:close()
		end
		width=widthstr:sub(1,1):byte()*16777216+widthstr:sub(2,2):byte()*65536+widthstr:sub(3,3):byte()*256+widthstr:sub(4,4):byte()
		height=heightstr:sub(1,1):byte()*16777216+heightstr:sub(2,2):byte()*65536+heightstr:sub(3,3):byte()*256+heightstr:sub(4,4):byte()
		return width,height
	end
	file:seek("set")
	-- Detect if BMP
	if file:read(2)=="BM" then
		--[[ 
			The strategy is:
			1. Seek to position 0x12
			2. Get value in little-endian order
		]]
		file:seek("set",18)
		local widthstr,heightstr=file:read(4),file:read(4)
		refresh()
		width=widthstr:sub(4,4):byte()*16777216+widthstr:sub(3,3):byte()*65536+widthstr:sub(2,2):byte()*256+widthstr:sub(1,1):byte()
		height=heightstr:sub(4,4):byte()*16777216+heightstr:sub(3,3):byte()*65536+heightstr:sub(2,2):byte()*256+heightstr:sub(1,1):byte()
		return width,height
	end
	-- Detect if JPG/JPEG
	file:seek("set")
	if file:read(2)=="\255\216" then
		--[[
			The strategy is
			1. Find necessary markers
			2. Store biggest value in variable
			3. Return biggest value
		]]
		local lastb,curb=0,0
		local xylist={}
		local sstr=file:read(1)
		while sstr~=nil do
			lastb=curb
			curb=sstr:byte()
			if (curb==194 or curb==192) and lastb==255 then
				file:seek("cur",3)
				local sizestr=file:read(4)
				local h=sizestr:sub(1,1):byte()*256+sizestr:sub(2,2):byte()
				local w=sizestr:sub(3,3):byte()*256+sizestr:sub(4,4):byte()
				if w>width and h>height then
					width=w
					height=h
				end
			end
			sstr=file:read(1)
		end
		if width>0 and height>0 then
			refresh()
			return width,height
		end
	end
	file:seek("set")
	-- Detect if GIF
	if file:read(4)=="GIF8" then
		--[[
			The strategy is
			1. Seek to 0x06 position
			2. Extract value in little-endian order
		]]
		file:seek("set",6)
		width,height=file:read(1):byte()+file:read(1):byte()*256,file:read(1):byte()+file:read(1):byte()*256
		refresh()
		return width,height
	end
	-- More image support
	file:seek("set")
	-- Detect if Photoshop Document
	if file:read(4)=="8BPS" then
		--[[
			The strategy is
			1. Seek to position 0x0E
			2. Get value in big-endian order
		]]
		file:seek("set",14)
		local heightstr,widthstr=file:read(4),file:read(4)
		refresh()
		width=widthstr:sub(1,1):byte()*16777216+widthstr:sub(2,2):byte()*65536+widthstr:sub(3,3):byte()*256+widthstr:sub(4,4):byte()
		height=heightstr:sub(1,1):byte()*16777216+heightstr:sub(2,2):byte()*65536+heightstr:sub(3,3):byte()*256+heightstr:sub(4,4):byte()
		return width,height
	end
	file:seek("end",-18)
	-- Detect if Truevision TGA file
	if file:read(10)=="TRUEVISION" then
		--[[
			The strategy is
			1. Seek to position 0x0C
			2. Get image width and height in little-endian order
		]]
		file:seek("set",12)
		width=file:read(1):byte()+file:read(1):byte()*256
		height=file:read(1):byte()+file:read(1):byte()*256
		refresh()
		return width,height
	end
	file:seek("set")
	-- Detect if JPEG XR/Tagged Image File (Format)
	if file:read(2)=="II" then
		-- It would slow, tell me how to get it faster
		--[[
			The strategy is
			1. Read all file contents
			2. Find "Btomlong" and "Rghtlong" string
			3. Extract values in big-endian order(strangely, II stands for Intel byte ordering(little-endian) but it's in big-endian)
		]]
		temp=file:read("*a")
		btomlong={temp:find("Btomlong")}
		rghtlong={temp:find("Rghtlong")}
		if #btomlong==2 and #rghtlong==2 then
			heightstr=temp:sub(btomlong[2]+1,btomlong[2]+5)
			widthstr=temp:sub(rghtlong[2]+1,rghtlong[2]+5)
			refresh()
			width=widthstr:sub(1,1):byte()*16777216+widthstr:sub(2,2):byte()*65536+widthstr:sub(3,3):byte()*256+widthstr:sub(4,4):byte()
			height=heightstr:sub(1,1):byte()*16777216+heightstr:sub(2,2):byte()*65536+heightstr:sub(3,3):byte()*256+heightstr:sub(4,4):byte()
			return width,height
		end
	end
	-- Video support
	file:seek("set",4)
	-- Detect if MP4
	if file:read(7)=="ftypmp4" then
		--[[
			The strategy is
			1. Seek to 0xFB
			2. Get value in big-endian order
		]]
		file:seek("set",0xFB)
		local widthstr,heightstr=file:read(4),file:read(4)
		refresh()
		width=widthstr:sub(1,1):byte()*16777216+widthstr:sub(2,2):byte()*65536+widthstr:sub(3,3):byte()*256+widthstr:sub(4,4):byte()
		height=heightstr:sub(1,1):byte()*16777216+heightstr:sub(2,2):byte()*65536+heightstr:sub(3,3):byte()*256+heightstr:sub(4,4):byte()
		return width,height
	end
	file:seek("set",8)
	-- Detect if AVI
	if file:read(3)=="AVI" then
		file:seek("set",0x40)
		width=file:read(1):byte()+file:read(1):byte()*256+file:read(1):byte()*65536+file:read(1):byte()*16777216
		height=file:read(1):byte()+file:read(1):byte()*256+file:read(1):byte()*65536+file:read(1):byte()*16777216
		refresh()
		return width,height
	end
	refresh()
	return nil
end

return GetImageWidthHeight
