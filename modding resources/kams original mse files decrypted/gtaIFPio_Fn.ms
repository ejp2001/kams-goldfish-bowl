-------------
--Import Fn--
-------------
fn ReadifpHeader f = (
    HeaderID = readLong f 
    if HeaderID == 0x4B504E41 then (		--GTA3/VC
	fileLength = readLong f
	if (readLong f) != 0x4F464E49 then (format "Error INFO![%]\n" (ftell f);return undefined)
	infoLenght = readLong f
	infostart = ftell f
	Anim_Count = readLong f
	intname = readString f
	skipbyte = 4 - (mod (intname.count + 1) 4)
	if skipbyte != 4 then fseek f skipbyte #seek_cur
	return #(Anim_Count, intname, HeaderID)
    )
    if HeaderID == 0x33504E41 then (		--SA
	fileLength = readLong f
	--check file size--
	fseek f 0 #seek_end
	endfile = ftell f
	if endfile < fileLength+8 then (format "Error filesize[%]\n" endfile; return undefined)
	fseek f 8 #seek_set
 	-------------------
	intname = readString f
	skipbyte = 23 - intname.count
	fseek f skipbyte #seek_cur
	Anim_Count = readLong f
	--format "Here:[%]\n" (ftell f)
	return #(Anim_Count, intname, HeaderID)
    )
    messagebox "Unknown ifp format!!!\n" title:"IFP Error"
    return undefined
)
--end fn ReadifpHeader						--<i1>--
--
fn ifpAnimInfo f NumAnim ver = (
	NameAry = #()
	AddressAry = #()
	if ver == 0x4B504E41 then (		--GTA3/VC
		for i = 1 to NumAnim do (
			append AddressAry (ftell f)
			if (readLong f) != 0x454D414E then (format "Error NAME![%]\n" (ftell f);return undefined)
			nameLength = readLong f
			Aname = readString f
			skipbyte = 4 - (mod nameLength 4)
			if (skipbyte > 0)AND(skipbyte < 4) then fseek f skipbyte #seek_cur
			append NameAry Aname
			if (readLong f) != 0x4E414744 then (format "Error DGAN![%]\n" (ftell f);return undefined)
			AnimLength = readLong f
			fseek f AnimLength #seek_cur	
		)--end for i	
	) else (					--SA
		for i = 1 to NumAnim do (
			append AddressAry (ftell f)
			Aname = readString f
			append NameAry Aname
			skipbyte = 23 - (Aname.count)
			fseek f skipbyte #seek_cur
			BoneCount = readLong f
			AnimLength = (readLong f) + (36 * BoneCount) + 4
			--format "Bones:[%]\t size:[%]\n" BoneCount AnimLength
			fseek f AnimLength #seek_cur
		)--end for i
	)
	return #(NameAry, AddressAry, ver)
)
--end fn ifpAnimInfo						--<i2>--
--
fn ApplyAnim f AllObjects noPOSkey stm ver = (
	tm = stm
	animationRange = interval tm (tm + 1)

	if ver == 0x4B504E41 then (		--GTA3/VC
		if (readLong f) != 0x454D414E then (format "Error NAME![%]\n" (ftell f);return undefined)
		nameLength = readLong f
		Aname = readString f
		skipbyte = 4 - (mod nameLength 4)
		if (skipbyte > 0)AND(skipbyte < 4) then fseek f skipbyte #seek_cur 
		if (readLong f) != 0x4E414744 then (format "Error DGAN![%]\n" (ftell f);return undefined)
		animLength = readLong f
		if (readLong f) != 0x4F464E49 then (format "Error INFO![%]\n" (ftell f);return undefined)
		skipbyte = (readLong f) - 4
		numParts = readLong f
		format "Total: % parts in this animation\n" numParts
		if (skipbyte > 0) then fseek f skipbyte #seek_cur 

		for kk = 1 to numParts do (
			if (readLong f) != 0x4E415043 then (format "Error CPAN![%]\n" (ftell f);return undefined)
			partLength = readLong f
			if (readLong f) != 0x4D494E41 then (format "Error ANIM![%]\n" (ftell f);return undefined)
			ADataLength = readLong f
			DataEND =  ADataLength + (ftell f)
			partName = readString f
			
			--Pad the text for easy reading--
			format "%:\t" partName
			if partName.count < 6 then format "\t"
			if partName.count < 13 then format "\t"
        
			skipbyte = 27 - partName.count
			if (skipbyte > 0) then fseek f skipbyte #seek_cur
			FrameCount = readLong f
			format "% keys  \t" FrameCount

			if ADataLength == 48 then (
				skipbyte = DataEND - (ftell f) - 8
				if (skipbyte > 0) then fseek f skipbyte #seek_cur
				s1 = readLong f
				s2 = readLong f
				format "%\t%\t" s1 s2

				mshary = for obj in AllObjects where obj.name == partName collect obj

			) else (
				skipbyte = DataEND - (ftell f) - 4
				if (skipbyte > 0) then fseek f skipbyte #seek_cur
				BoneID = readLong f
				format "ID:%\t" BoneID
				
				mshary = for obj in AllObjects where (getUserProp obj "BoneID") == BoneID collect obj
			)

			if mshary != undefined then msh = mshary[1]
			else msh = undefined

			--format "%[%]\n" (readString f) (ftell f)
			FrameType = readLong f
			FrameLength = readLong f
			
			case FrameType of (
				--KRT0
				0x3054524B:(
					format "KRT0\n"
					for j = 1 to FrameCount do (
						rot = conjugate (quat (readFloat f) (readFloat f) (readFloat f) (readFloat f))
						tlt = [(readFloat f),(readFloat f),(readFloat f)]
						tm = ((readFloat f) * framerate) + stm
						--msh = undefined
						--for obj in AllObjects where obj.name == partName do msh = obj
						if msh != undefined then (
							if BoneID != undefined then setUserProp msh "BoneID" BoneID
							with animate on at time tm (
								in coordsys parent (
									bkup = msh.pos
									msh.pos = [0,0,0]
									msh.rotation = rot
									if noPOSkey then msh.pos = bkup
									else msh.pos = tlt
									pc = msh.pos.controller
									tk = (getKeyIndex pc tm) 
									try (
										pc.keys[tk].OutTangentType = #linear
										pc.keys[tk].InTangentType = #linear
									)catch()
								)--end coordsys
							)--end with animate
							if j == 2 then (
								try (
									msh.pos.controller.keys[((getKeyIndex msh.pos.controller tm) - 1)].InTangentType = #step
									msh.pos.controller.keys[((getKeyIndex msh.pos.controller tm) - 1)].OutTangentType = #linear
								)catch()
							)--end if j 	
						)--end if msh
					)--end for j
				)
				--KR00
				0x3030524B:(
					format "KR00\n"
					for j = 1 to FrameCount do (
						rot = conjugate (quat (readFloat f) (readFloat f) (readFloat f) (readFloat f))
						tm = ((readFloat f) * framerate) + stm
						--msh = undefined
						--for obj in AllObjects where obj.name == partName do msh = obj
						if msh != undefined then (
							if BoneID != undefined then setUserProp msh "BoneID" BoneID
							with animate on at time tm (
								in coordsys parent (
									bkup = msh.pos
									msh.pos = [0,0,0]
									msh.rotation = rot
									msh.pos = bkup
								)--end in coordsys
							)--end with animate
							--if j > 1 then deletekey msh.pos.controller (getKeyIndex msh.pos.controller tm)
							if tm != stm then (
								tk = numkeys msh.pos.controller
								try ( deletekey msh.pos.controller tk) catch()
							)--end if tm
						)--end if msh
					)--end for j
				)
				--KRTS
				0x5354524B:(
					format "KRTS\n"
					for j = 1 to FrameCount do (
						rot = conjugate (quat (readFloat f) (readFloat f) (readFloat f) (readFloat f))
						tlt = [(readFloat f),(readFloat f),(readFloat f)]
						scl = [(readFloat f),(readFloat f),(readFloat f)]
						tm = ((readFloat f) * framerate) + stm
						--msh = undefined
						--for obj in AllObjects where obj.name == partName do msh = obj
						if msh != undefined then (
							if BoneID != undefined then setUserProp msh "BoneID" BoneID
							with animate on at time tm (
								in coordsys parent (
									bkup = msh.pos
									msh.pos = [0,0,0]
									msh.rotation = rot
									msh.scale = scl
									if noPOSkey then msh.pos = bkup
									else msh.pos = tlt
									pc = msh.pos.controller
									tk = (getKeyIndex pc tm) 
									try (
										pc.keys[tk].OutTangentType = #linear
										pc.keys[tk].InTangentType = #linear
									)catch()
								)--end in coordsys
							)--end with animate
							if j == 2 then (
								try (
									msh.pos.controller.keys[((getKeyIndex msh.pos.controller tm) - 1)].InTangentType = #step
									msh.pos.controller.keys[((getKeyIndex msh.pos.controller tm) - 1)].OutTangentType = #linear
								) catch()
							)--end if j
						)--end if msh
					)--end for j
				)
			)--end case
			if tm > animationRange.end then animationRange =animationRange =(interval 0 tm)
			--format "This animation time: %\n\n" (tm/framerate)
		)--end for kk
		format "This animation time: %\n\n" ((tm-stm)/framerate)
	) else (					--SA
		Aname = readString f
		skipbyte = 23 - (Aname.count)
		fseek f skipbyte #seek_cur
		BoneCount = readLong f
		AnimLength = (readLong f) + (36 * BoneCount) + 4
		unkwn = readLong f
		if unkwn != 1 then ( Format "%'s unknown:[%]!!!\n" Aname unkwn )
		format "Total: % bones in this animation\n\n" BoneCount
		for kk = 1 to BoneCount do (
			--Skip bone name--
			Bname = readString f
			skipbyte = 23 - (Bname.count)
			fseek f skipbyte #seek_cur
			------------------
			KeyType = readLong f
			if (KeyType<3)OR(KeyType>4) then ( Format "Special KeyType:[%]\n" KeyType)
			FrameCount = readLong f
			boneID =  readLong f
			format "%[%]:\tkeys[%]:%\t" Bname boneID KeyType FrameCount
			for j = 1 to FrameCount do (
				--Rotation Data--
				qx = (readShort f)/4096.0
				qy = (readShort f)/4096.0
				qz = (readShort f)/4096.0
				qw = (readShort f)/4096.0
				--rot = conjugate (quat qx qy qz qw)
				rot =  (quat qx qy qz qw)
				--Time--
				tm = ( (readShort f)/60.0 * framerate ) + stm
				--Pos--
				if KeyType == 4 then (
					px = (readShort f)/1024.0
					py = (readShort f)/1024.0
					pz = (readShort f)/1024.0
					tlt = [px,py,pz]
				)--end pos key
				--format "AllObjects[%]:%\n" AllObjects.count AllObjects
				tmp = for obj in AllObjects where (getUserProp obj "BoneID") == boneID collect obj
				SAbone = tmp[1]
				--format "->%\n" SAbone
				if SAbone != undefined then (
					with animate on at time tm (
						--SAbone.rotation = rot
						in coordsys parent (
							bkup = SAbone.pos
							SAbone.pos = [0,0,0]
							SAbone.rotation = rot
							SAbone.pos = bkup
						)
						if (KeyType == 4)AND(noPOSkey==False) then (
							if SAbone.parent != undefined then
								in coordsys parent ( SAbone.pos = tlt )
							else SAbone.pos = tlt
							pc = SAbone.pos.controller
							tk = (getKeyIndex pc tm) 
							try (
								pc.keys[tk].OutTangentType = #linear
								pc.keys[tk].InTangentType = #linear
							)catch()
						) else (	--deleteKeys SAbone.pos.controller )
							if tm != stm then (
								tk = numkeys SAbone.pos.controller
								try ( deletekey SAbone.pos.controller tk) catch()
							)
						)
					)--end with animate
				)--end if SAbone
			)--end for j	
			if tm > animationRange.end then animationRange =animationRange =(interval 0 tm)
			format "time: %\n" (tm/framerate)
		)--end for kk
	)
	gc()
)
--end fn ApplyAnim						--<i3>--
--
fn resetPost AllObjects keytime = (
	sliderTime = keytime
	for obj in AllObjects do (
		try (
			with animate on at time keytime (
				tp 					= readvalue ((getUserProp obj "OrgRot") as stringstream)
				tpW					= getUserProp obj "OrgRotW"
				obj.rotation = (quat tp.x tp.y tp.z tpW)
				obj.scale	= readvalue ((getUserProp obj "Orgscl") as stringstream)
				obj.pos	= readvalue ((getUserProp obj "OrgPos") as stringstream)
			)
			pc = obj.pos.controller
			ps = obj.scale.controller
			tk = (getKeyIndex pc keytime) - 1
			if tk > 0 then (
				pc.keys[tk].InTangentType = #linear
				pc.keys[tk].OutTangentType = #step
				pc.keys[(tk + 1)].InTangentType = #step
				pc.keys[(tk + 1)].OutTangentType = #linear
			)
			tk = (getKeyIndex ps keytime) - 1
			if tk > 0 then (
				ps.keys[tk].InTangentType = #linear
				ps.keys[tk].OutTangentType = #step
				ps.keys[(tk + 1)].InTangentType = #step
				ps.keys[(tk + 1)].OutTangentType = #linear
			)
		) catch (return false)
	)--end for i
	return true
)
--end fn resetPost						--<i4>--
--
--2-------------
--SA Export Fn--
----------------
fn myInsertItem Ary itm idx = (
	for i = Ary.count to idx by -1 do Ary[(i + 1)] = Ary[i]
	Ary[idx] = itm
)
--
fn SortByBoneID AllObjects = (
	BIDAry = #()
	BobjAry = #()
	for bne in AllObjects do (
		bid = getUserProp bne "BoneID"
		if bid != undefined then (
			if bid >= 0 then (		
				if (BIDAry.count == 0)OR(bid > BIDAry[BIDAry.count]) then (
					append BIDAry bid
					append BobjAry bne
				) else (
					for i = 1 to BIDAry.count do (
						if bid < BIDAry[i] then (
							myInsertItem BIDAry bid i
							myInsertItem BobjAry bne i
							exit
						)--end if bid
					)--end for i
				)--end if/else
			)--end if bid >= 0
		)--end if bid != undefined
	)--end for bne
	return #(BIDAry, BobjAry)
)--end fn SortByBoneID

fn SyncTRKeys obj = (  
	pc = obj.pos.controller
	pr = obj.rotation.controller

	bkpc = undefined
	bkpr = undefined
	if classof pr != tcb_rotation then (
		bkpr = classof pr
		pr = tcb_rotation()
	)
	if classof pc != bezier_position then (
		bkpc = classof pc
		pc = bezier_position()
	)	
	
	for i = 1 to pc.keys.count do (
		tm = getKeyTime pc i
		if (getKeyIndex pr tm) == 0 then addNewKey pr tm
	)--end for i
	for i = 1 to pr.keys.count do (
		tm = getKeyTime pr i
		if (getKeyIndex pc tm) == 0 then (
			addNewKey pc tm
			kidx = getKeyIndex pc tm
			pc.keys[kidx].OutTangentType = #linear
			pc.keys[kidx].InTangentType = #linear
		)
	)--end for i	

	--if bkpc != undefined then execute ( "obj.pos.controller = " + (bkpc as string) + "()" )
	--if bkpr != undefined then execute ( "obj.rotation.controller = " + (bkpr as string) + "()" )

)
--end SyncTRKeys
--
fn GetAnmKeysObjs AllObjects = (
	AnmObjAry = #()
	ByteCount = 0
	for bne in AllObjects do (
		bid = getUserProp bne "BoneID"
		if bid != undefined then (
			if bid >= 0 then ( 
				if bne.pos.controller.keys.count > 1 then (
					append AnmObjAry bne
					SyncTRKeys bne
					ByteCount += (bne.pos.controller.keys.count) * 16
				)
				else if bne.rotation.controller.keys.count > 1 then (
					append AnmObjAry bne
					ByteCount += (bne.rotation.controller.keys.count) * 10
				)
			)--end if bid >= 0
		)--end if bid == undefined				
	)--end for
	return #(AnmObjAry, ByteCount)
)
--end fn GetAnmKeysObjs
--
fn ExpsaIFP f AllObjects AnmName = (
	st = ftell f
	KOAry = GetAnmKeysObjs AllObjects
	if KOAry[2] == 0 then return undefined
	
	writeString f AnmName
	for i = 1 to (23 - AnmName.count) do writeByte f 0 
	writeLong f KOAry[1].count
	writeLong f KOAry[2]
	writeLong f 1
	
	BAry = SortByBoneID KOAry[1]
	for bne in BAry[2] do (
		writeString f bne.name
		for i = 1 to (23 - bne.name.count) do writeByte f 0
		
		if bne.pos.controller.keys.count > 1 then writeLong f 4
		else writeLong f 3
		
		writeLong f (bne.rotation.controller.keys.count)
		
		writeLong f (getUserProp bne "BoneID")
	
		pr = bne.rotation.controller
		--bkpr = undefined
		--if classof pr != tcb_rotation then (
			--bkpr = classof pr
			--pr = tcb_rotation()
		--)
		for j = 1 to pr.keys.count do (

			tm = getKeyTime pr j
			at time tm (

				if bne.parent != undefined then
					in coordsys parent ( rot = bne.rotation )
				else 		rot = bne.rotation

				writeShort f ((rot.x * 4096) as integer)
				writeShort f ((rot.y * 4096) as integer)
				writeShort f ((rot.z * 4096) as integer)
				writeShort f ((rot.w * 4096) as integer)
				
				val = ((tm/framerate * 60) as string) as float
				if val - (val as integer) > 0.5 then val += 1
				writeShort f ( val )
				
				if bne.pos.controller.keys.count > 1 then (
					if bne.parent != undefined then
						in coordsys parent 	trn = bne.pos
					else 	trn = bne.pos
					writeShort f ((trn.x * 1024) as integer)
					writeShort f ((trn.y * 1024) as integer)
					writeShort f ((trn.z * 1024) as integer)
				)--if posKey
				
			)--end at time tm
		)--end for j
		--format ">>\n"		
		--if bkpr != undefined then execute ( "bne.rotation.controller = " + (bkpr as string) + "()" )
		
	)--end for bne
	return ((ftell f) - st)
)
--end fn ExpsaIFP
--
--3-------------
--VC Export Fn--
----------------
fn HierarchtSet objset = (
	HieAry = #()
	--siblAry = #()
	local thisbase
	--Get Root--
	for obj in objset where (obj.parent == undefined) do (thisbase = obj)
	--format "Root:%\n" thisbase
	if (getUserProp thisbase "BoneID") == 0 then append HieAry thisbase
	--Loop--
	doloop = true
	branch = #()
	while doloop == true do (
		tmp =  thisbase.children
		if (tmp.count == 0) then (
			if branch.count == 0 then doloop = false
			else (
				idx = branch[branch.count]
				--format "idx:%\n" idx
				thisbase = HieAry[idx][(HieAry[idx].count - 1)]
				append HieAry thisbase
				deleteitem HieAry[idx] (HieAry[idx].count - 1)
				if HieAry[idx].count == 1 then (
					deleteitem branch branch.count
					HieAry[idx] = HieAry[idx][1]
				)
			)
		) else (
			if tmp.count == 1 then (
				append HieAry tmp[1]
				thisbase = tmp[1]
			) else (
				tt = for obj in tmp collect obj
				append HieAry tt
				thisbase = tmp[tmp.count] 
				append branch HieAry.count
			)
		)--end if/else
	)--end while
	
	--for hh in HieAry do format "->%\n" hh
			
	siblAry = for ii in HieAry collect [-111,-1]
	for ii = 1 to siblAry.count do (
		siblAry[ii].x = ii
		tmp = HieAry[ii].children
		if tmp.count == 0 then siblAry[ii].x = -1
	)--end for ii
	dupAt = #()
	for ii = 1 to siblAry.count do (
		tmp = HieAry[ii].children	
		if tmp.count > 1 then (
			for jj = 2 to tmp.count do (
				idx = finditem HieAry tmp[jj]
				chainend = idx
				while (siblAry[chainend].x != -1) do chainend += 1
				siblAry[idx].y = chainend
				append dupAt siblAry[idx]
			)--end for jj		
		)--end if
	)--end for ii
	----------------------
	--sort out dup chain--
	----------------------
	loopend = false
	while loopend != true  do (
		local tidx = undefined
		for j = 1 to dupAt.count do 
			if dupAt[j].x == -1 then 	tidx = j
		if 	tidx == undefined then loopend = true
		else (	
			mtch = dupAt[tidx].y
			deleteitem dupAt tidx	--;format "Match at: % -> %\n" tidx mtch		

			tidx = undefined
			for j = 1 to dupAt.count do 
				if dupAt[j].y == mtch then	tidx = j
			if 	tidx != undefined then (
				chge = dupAt[tidx].x
				deleteitem dupAt tidx	--;format "Change at: % -> %\n" tidx chge		

				for j = 1 to dupAt.count do 
					if HieAry[dupAt[j].x].parent == HieAry[chge].parent \
						then		tidx = j
				siblAry[chge].y = dupAt[tidx].x - 1
				deleteitem dupAt tidx
			)--end if
		)--end if/else
	)--end while

	--for ss in siblAry do format "->%\n" ss

	return #(HieAry,siblAry)

)
--end fn HierarchtSet						--<e1>--
--
fn CheckKeys obj = (
	pkeys = numkeys obj.position.controller
	rkeys = numkeys obj.rotation.controller
	skeys = numkeys obj.scale.controller
	if (pkeys < 2)AND(rkeys < 2)AND(skeys < 2) \
		then return undefined                           				--no animation
	keytimeAry = for t in obj.rotation.controller.keys collect t.time
	if (pkeys < 2)AND(skeys < 2) then return #("KR00",keytimeAry) 		--KR00
	for t in obj.position.controller.keys where \
		(finditem keytimeAry t.time) == 0 do (append keytimeAry t.time)
	if (skeys < 2) then return #("KRT0",keytimeAry)          			--KRT0
	for t in obj.scale.controller.keys where \
		(finditem keytimeAry t.time) == 0 do (append keytimeAry t.time)
	return #("KRTS",keytimeAry)											--KRTS
)
--end fn CheckKeys						--<e2>--
--
fn SyncKeys obj = (    
	tmp = CheckKeys obj
	if tmp == undefined then 		return undefined                --skip this obj  
	keytype = tmp[1]
	keytimeAry = tmp[2]
	if keytype == "KR00" then return keytype
	sort keytimeAry
	for t in keytimeAry where ((getKeyIndex obj.rotation.controller t) == 0) \
		do (addNewKey obj.rotation.controller t)
	for t in keytimeAry where ((getKeyIndex obj.position.controller t) == 0) \
		do (addNewKey obj.position.controller t)
	if keytype == "KRT0" then return keytype
	for t in keytimeAry where ((getKeyIndex obj.scale.controller t) == 0) \
		do (addNewKey obj.scale.controller t)
	return keytype                
)--end fn SyncKeys						--<e3>--
--
fn CPANout f obj useID sibling KeyType = (
	--CPAN cpanlegnth					>2 (cpanlegnth = keyspaces * 4)
	--ANIM	animlength(44 or 48 bytes)	>2
	--name(28Bytes)					>7
	--FrameCount start end				>3				
	--ObjectID	OR Silbing				>1 or 2
	--FrameType	framelength		>2

	FrameCount = numKeys obj.rotation.controller

	keyspaces = 15
	if useID == false then keyspaces += 1
	keyspaces += case KeyType of (
		"KR00": 5 *  FrameCount
		"KRT0": 8 *  FrameCount
		"KRTS": 11 * FrameCount
		default: 0    
	)    
	cpanlegnth = keyspaces * 4
    
	writeLong f 0x4E415043  --CPAN
	writeLong f cpanlegnth
	writeLong f 0x4D494E41  --ANIM
	if useID == true then writeLong f 44
	else writeLong f 48
	writeString f obj.name
	for i = 1 to (27 - obj.name.count) do writeByte f 0
	writeLong f FrameCount
	writeLong f 0    
	writeLong f (FrameCount - 1)
	if useID == true then writeLong f (GetUserProp obj "BoneID")
	else (
		writeLong f sibling.x
		writeLong f sibling.y
	)
	case KeyType of (
		"KR00": (
				writeLong f 0x3030524B
				writeLong f (FrameCount * 20)
				for j = 1 to FrameCount do (
					keytime = getKeyTime obj.rotation.controller j 
					at Time keytime (
						in coordsys parent (
							bkup = obj.pos
							obj.pos = [0,0,0]
							trot = conjugate obj.rotation
							obj.pos = bkup
						)
					)
					writeFloat f trot.x
					writeFloat f trot.y
					writeFloat f trot.z
					writeFloat f trot.w
					writeFloat f ((getKeyTime obj.rotation.controller j)/FrameRate)
				)--end for j
		)
		"KRT0": (
				writeLong f 0x3054524B
				writeLong f (FrameCount * 32)
				for j = 1 to FrameCount do (
					keytime = getKeyTime obj.rotation.controller j
					at Time keytime (
						--in coordsys parent (
							tpos = obj.pos
							trot = conjugate obj.rotation
						--)
					)
					writeFloat f trot.x
					writeFloat f trot.y
					writeFloat f trot.z
					writeFloat f trot.w
					writeFloat f tpos.x
					writeFloat f tpos.y
					writeFloat f tpos.z
					writeFloat f ((getKeyTime obj.rotation.controller j)/FrameRate)
				)--end for j
		)
		"KRTS": (
				writeLong f 0x5354524B
				writeLong f (FrameCount * 44)
				for j = 1 to FrameCount do ( 
					keytime = getKeyTime obj.rotation.controller j
					at Time keytime (
						in coordsys parent (
							trot = conjugate obj.rotation
							tpos = obj.pos
							tscl = obj.scale
						)
					)
					writeFloat f trot.x
					writeFloat f trot.y
					writeFloat f trot.z
					writeFloat f trot.w
					writeFloat f tpos.x
					writeFloat f tpos.y
					writeFloat f tpos.z
					writeFloat f tscl.x
					writeFloat f tscl.y
					writeFloat f tscl.z
					writeFloat f ((getKeyTime obj.rotation.controller j)/FrameRate)
				)--end for j
		)
	)--end case
	
	return (cpanlegnth + 8)
)
--end fn CPANout 						--<e4>--
--
fn expAnim f AllObjAry useBoneID animName = (
	--NAME nameLength			>2
	--animName
	--DGAN dganLength		>2
	--INFO infoLength(8)		>2
	--obj_count null(0)		>2 		
	gc()
	
	obj_count = 0
	dganLength = 16

    --check if all objs have BoneIDs, else use silbing in stead
    if useBoneID == true then (
        voidIDs = true
        for i =  1 to AllObjAry.count do (
			if AllObjAry[i].parent != undefined then 
	            if (getUserProp AllObjAry[i] "BoneID") == undefined then voidIDs = false
        )
    ) else voidIDs = false
    if voidIDs == true then extlength = 0 else extlength = 4

    --format "BoneID OK:%\n%\n" voidIDs AllObjAry

	tmp = HierarchtSet AllObjAry
	ObjOrderAry = tmp[1]
	SiblingAry = tmp[2]

	ktypeAry = #()
    --calculate how many 'bytes' for Animation (CPAN)
    for i = ObjOrderAry.count to 1 by -1 do (
        ktype = SyncKeys ObjOrderAry[i]
        dganLength += case ktype of (
            "KR00": (20 * (numKeys ObjOrderAry[i].rotation.controller)) + 68 + extlength
            "KRT0": (32 * (numKeys ObjOrderAry[i].rotation.controller)) + 68 + extlength
            "KRTS": (44 * (numKeys ObjOrderAry[i].rotation.controller)) + 68 + extlength
            default: 0    
        )
		if ktype != undefined then (
			obj_count += 1
			append ktypeAry ktype
		) else (
			deleteitem ObjOrderAry i
			deleteitem SiblingAry i
			for j = i to SiblingAry.count do (
				if SiblingAry[j].x != -1 then SiblingAry[j].x -= 1
				if SiblingAry[j].y != -1 then SiblingAry[j].y -= 1
			)
		)
    )--end for i

	local noffset = mod (animName.count + 1) 4
	
	writeLong f 0x454D414E		--NAME
	writeLong f (animName.count + 1)
	writeString f animName
	if noffset != 0 then for j = 1 to (4 - noffset) do writeByte f 0
	writeLong f 0x4E414744		--DGAN
	writeLong f dganLength
	writeLong f 0x4F464E49		--INFO
	writeLong f 8				--infolength
	writeLong f obj_count
	writeLong f 0
    
	for i = 1 to ObjOrderAry.count do (
		if voidIDs == true then format "ID:%\tExporting %...\n" (getUserProp ObjOrderAry[i] "BoneID") ObjOrderAry[i].name
		else format "%  \tExporting %...\n" SiblingAry[i] ObjOrderAry[i].name
		
		CPANout f ObjOrderAry[i] voidIDs SiblingAry[i] ktypeAry[(ObjOrderAry.count - i + 1)]
	)
	if noffset != 0 then extoffset = (4 - noffset) else extoffset = 0
	
	gc()
	
	return (dganLength + 16 + animName.count + 1 + extoffset)
)
--end fn expAnim							--<e5>-- Max Main --
--
--4---------------
--GMax Export Fn--
------------------
fn stripSpace str = (
	local tmp = ""
	for i = 1 to str.count do (
		if substring str i 1 == " " then tmp += "~"
		else tmp += substring str i 1
	)--end for i
	return tmp
)
--end fn stripSpace						--<GM1>--
--
fn gExpsaIFP ss AllObjects AnimName = (
	KOAry = GetAnmKeysObjs AllObjects
	if KOAry[2] == 0 then return undefined

	format "//Animation % start Here\n" animName		to:ss
	format "c 24\n%\n" (stripSpace animName)			to:ss
	--format "c %\n%\n" animName.count (stripSpace animName)			to:ss
	--tmp = 24 - animName.count
	--format "b %\n" tmp		to:ss
	--for i = 1 to tmp do format "0 "		to:ss
	--format "\n"		to:ss
	format "i 3\n% % %\n" KOAry[1].count KOAry[2] 1 		to:ss

	BAry = SortByBoneID KOAry[1]
	for bne in BAry[2] do (    
    
		format "c 24\n%\n" (stripSpace bne.name)		to:ss
		--format "c %\n%\n" bne.name.count (stripSpace bne.name)		to:ss
		--format "b %\n"  (24 - bne.name.count) 		to:ss
		--for i = 1 to (24 - bne.name.count) do format "0 "		to:ss
		--format "\n"		to:ss
    
		if bne.pos.controller.keys.count > 1 then format "i 3\n4 "		to:ss
		else format "i 3\n3 "		to:ss

		format "% " (bne.rotation.controller.keys.count)		to:ss

		format "%\n" (getUserProp bne "BoneID")		to:ss

		pr = bne.rotation.controller
		for j = 1 to pr.keys.count do (

			tm = getKeyTime pr j
			at time tm (

				if bne.parent != undefined then
					in coordsys parent ( rot = bne.rotation )
				else 		rot = bne.rotation

				r1 = (rot.x * 4096) as integer
				r2 = (rot.y * 4096) as integer
				r3 = (rot.z * 4096) as integer
				r4 = (rot.w * 4096) as integer 
				val = ((tm/framerate * 60) as string) as float
				if val - (val as integer) > 0.5 then val += 1
				format "w 5\n% % % % %\n" r1 r2 r3 r4 (val as integer)		to:ss
	
				if bne.pos.controller.keys.count > 1 then (
					if bne.parent != undefined then
						in coordsys parent 	trn = bne.pos
					else 	trn = bne.pos
					p1 = (trn.x * 1024) as integer
					p2 = (trn.y * 1024) as integer
					p3 = (trn.z * 1024) as integer
					format "w 3\n% % %\n" p1 p2 p3		to:ss
				)--if posKey

			)--end at time tm
		)--end for j
	)--end for bne
	
	--format "%\n" (ss as string)
	thislenght = KOAry[2]  + (KOAry[1].count * 36) + 36
    return thislenght
)
--end fn gExpsaIFP						--<GM2>-- GMax Main --
--
fn gm_CPANout ss obj useID sibling KeyType = (
	--CPAN cpanlegnth				>2 (cpanlegnth = keyspaces * 4)
	--ANIM	animlength(44 or 48 bytes)	>2
	--name(28Bytes)					>7
	--FrameCount start end				>3				
	--ObjectID	OR Silbing				>1 or 2
	--FrameType	framelength		>2

	FrameCount = numKeys obj.rotation.controller

	keyspaces = 15
	if useID == false then keyspaces += 1
	keyspaces += case KeyType of (
		"KR00": 5 *  FrameCount
		"KRT0": 8 *  FrameCount
		"KRTS": 11 * FrameCount
		default: 0    
	)    
	cpanlegnth = keyspaces * 4
    
	format "c 4\nCPAN\ni 1\n%\n" cpanlegnth 							to:ss
	if useID == true then al =  44
	else al = 48	
	format "c 4\nANIM\ni 1\n%\n" al										to:ss
	format "c 28\n%\n" (stripSpace obj.name)							to:ss
	if useID == true then (
		format "i 4\n% 0 % %\n" FrameCount \ 
		(FrameCount - 1) (GetUserProp obj "BoneID")					to:ss
	) else (
		format "i 5\n% 0 % % %\n" FrameCount \ 
		(FrameCount - 1) (sibling.x as integer) (sibling.y as integer)	to:ss
	)
	format "c 4\n%\n" KeyType											to:ss
	case KeyType of (
		"KR00": (
			format "i 1\n%\nf %\n" (FrameCount * 20) (FrameCount * 5)	to:ss
			for j = 1 to FrameCount do (
				keytime = getKeyTime obj.rotation.controller j 
				dtm = [keytime/FrameRate,0]
				at Time keytime (
					in coordsys parent (
						bkup = obj.pos
						obj.pos = [0,0,0]
						trot = conjugate obj.rotation
						obj.pos = bkup
					)
				)
				format "% % % % " trot.x trot.y trot.z trot.w			to:ss
				format "%\n" dtm.x										to:ss
			)--end for j
		)
		"KRT0": (
			format "i 1\n%\nf %\n" (FrameCount * 32) (FrameCount * 8)	to:ss
			for j = 1 to FrameCount do (
				keytime = getKeyTime obj.rotation.controller j
				dtm = [keytime/FrameRate,0]
				at Time keytime (
			--		in coordsys parent (
						tpos = obj.pos
						trot = conjugate obj.rotation
			--		)
				)
				format "% % % % " trot.x trot.y trot.z trot.w			to:ss
				format "% % % " tpos.x tpos.y tpos.z					to:ss
				format "%\n" dtm.x										to:ss
			)--end for j
		)
		"KRTS": (
			format "i 1\n%\nf %\n" (FrameCount * 44) (FrameCount * 11)	to:ss
			for j = 1 to FrameCount do ( 
				keytime = getKeyTime obj.rotation.controller j
				dtm = [keytime/FrameRate,0]
				at Time keytime (
					in coordsys parent (
						trot = conjugate obj.rotation
						tpos = obj.pos
						tscl = obj.scale
					)
				)
				format "% % % % " trot.x trot.y trot.z trot.w			to:ss
				format "% % % \n" tpos.x tpos.y tpos.z					to:ss
				format "% % % \n" tscl.x tscl.y tscl.z					to:ss
				format "%\n" dtm.x										to:ss
			)--end for j
		)
	)--end case
	
	return (cpanlegnth + 8)
)
--end fn gm_CPANout 						--<GM3>--
--
fn gm_expAnim ss AllObjAry useBoneID animName = (
	--NAME nameLength		>2
	--animName
	--DGAN dganLength		>2
	--INFO infoLength(8)		>2
	--obj_count null(0)		>2 		
	
	obj_count = 0
	dganLength = 16

    --check if all objs have BoneIDs, else use silbing in stead
    if useBoneID == true then (
        voidIDs = true
        for i =  1 to AllObjAry.count do (
			if AllObjAry[i].parent != undefined then 
	            if (getUserProp AllObjAry[i] "BoneID") == undefined then voidIDs = false
        )
    ) else voidIDs = false
    if voidIDs == true then extlength = 0 else extlength = 4
	
	tmp = HierarchtSet AllObjAry
	ObjOrderAry = tmp[1]
	SiblingAry = tmp[2]

	ktypeAry = #()
    --calculate how many 'bytes' for Animation (CPAN)
    for i = ObjOrderAry.count to 1 by -1 do (
        ktype = SyncKeys ObjOrderAry[i]
        dganLength += case ktype of (
            "KR00": (20 * (numKeys ObjOrderAry[i].rotation.controller)) + 68 + extlength
            "KRT0": (32 * (numKeys ObjOrderAry[i].rotation.controller)) + 68 + extlength
            "KRTS": (44 * (numKeys ObjOrderAry[i].rotation.controller)) + 68 + extlength
            default: 0    
        )
		if ktype != undefined then (
			obj_count += 1
			append ktypeAry ktype
		) else (
			deleteitem ObjOrderAry i
			deleteitem SiblingAry i
			for j = i to SiblingAry.count do (
				if SiblingAry[j].x != -1 then SiblingAry[j].x -= 1
				if SiblingAry[j].y != -1 then SiblingAry[j].y -= 1
			)
		)
    )--end for i
	
	al = ((animName.count/4) + 1) * 4
	
	format "//Animation % start Here\n" animName		to:ss
	format "c 4\nNAME\ni 1\n%\n" (animName.count + 1)	to:ss
	format "c %\n%\n" al (stripSpace animName)			to:ss
	format "c 4\nDGAN\ni 1\n%\n" dganLength				to:ss
	format "c 4\nINFO\ni 3\n8 % 0\n" obj_count			to:ss
	
	for i = 1 to ObjOrderAry.count do (
		--if voidIDs == true then format "ID:%\tExporting %...\n" (getUserProp ObjOrderAry[i] "BoneID") ObjOrderAry[i].name
		--else format "%  \tExporting %...\n" SiblingAry[i] ObjOrderAry[i].name

		gm_CPANout ss ObjOrderAry[i] voidIDs SiblingAry[i] ktypeAry[(ObjOrderAry.count - i + 1)]
	)
	tt = (((animName.count/4) + 1) * 4) + 16 + dganLength
	return tt
)
--end fn gm_expAnim						--<GM4>-- GMax Main --



fn IFPioInfo = (
	format "\nIFPio version 1.1\n"
	format "   - for both Max & GMax\n\n"
	format "by Kam\t\t14Oct05\n"
	format "kam.lai@ntlworld.com\n"
	return 051014
)--end fn IFPioInfo