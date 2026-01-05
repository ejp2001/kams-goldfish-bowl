fn writeCOL3 dff f ver = (
	cf = fopen dff "rb"
	fseek cf 8 #seek_set
	if ver != 0X1803FFFF then return false

	fseek cf 24 #seek_set
	objCount = readLong cf

	fseek cf 40 #seek_set        --FrameList
	skip =  (readLong cf) + 8
	fseek cf skip #seek_cur      --GeometryList
	skip =  (readLong cf) + 8
	fseek cf skip #seek_cur      --Atomic

	for i = 1 to objCount do (
		skip = (readLong cf) + 8        
		fseek cf skip #seek_cur      --Atomic
	)
 --New Edit(18Jul05)--**
		--Make sure it is COL3--
		col3leng = (readLong cf) - 12
		fseek cf 16 #seek_cur
		if ( readLong cf == 0x334C4F43 ) then fseek cf -4 #seek_cur
		else (
			while (readLong cf != 0x334C4F43) do ()
			fseek cf -24 #seek_cur
			col3leng = (readLong cf) - 12
			fseek cf 16 #seek_cur
		)
 --**

 --	fseek cf  16 #seek_cur           --Now at the start of COL3

	writeLong f 0X0253F2FA          --SA Appended COL
	writeLong f col3leng
	writeLong f ver 
	for i = 1 to col3leng do writeByte f (readByte cf)

	fclose cf

	return true
)

fn writeCOLL col f ver = (
	cf = fopen col "rb"
	fseek cf 0 #seek_end
	colleng = ftell cf
	fseek cf 0 #seek_set
    
	writeLong f 0X0253F2FA          --SA Appended COL
	writeLong f colleng
	writeLong f ver     
    for i = 1 to colleng do writeByte f (readByte cf)    
    
	fclose cf
	return true    
)
---------------------------------------------------------------------------

fn checkRoot AllObjects = (
	objset = AllObjects as array
	RootAry = for obj in objSet where
		(finditem objset obj.parent) == 0  collect obj
	if RootAry.count == 1 then return RootAry[1]
	else (
		messagebox "More than 1 Hierarchy links were selected!\nOnly 1 is allowed in dff." title:"Hierarchy Error"
		return undefined
	)
)--end fn checkRoot

fn singleCOL cf = (
	fseek cf 0 #seek_end
	cfend = ftell cf
	fseek cf 0 #seek_set
	headerID = readLong cf				--"COLL" or "COL3"
	if (headerID == 0x334C4F43)OR(headerID == 0x4C4C4F43) then (
		endCOL = readLong cf
		fseek cf endCOL #seek_cur
		if (ftell cf) == cfend then return true
		headerID = readLong cf
		if (headerID == 0x334C4F43)OR(headerID == 0x4C4C4F43) then return false
		return true
	) else return undefined
)--end fn singleCOL

fn findCOL3 cf ver = (
	fseek cf 8 #seek_set
	if (readLong cf) != ver then return false
	try (
		fseek cf 24 #seek_set
		objCount = readLong cf
    
		fseek cf 40 #seek_set        --FrameList
		skip =  (readLong cf) + 8
		fseek cf skip #seek_cur      --GeometryList
		skip =  (readLong cf) + 8
		fseek cf skip #seek_cur      --Atomic
        
		for i = 1 to objCount do (
			skip = (readLong cf) + 8        
			fseek cf skip #seek_cur      --Atomic
		)

		--Make sure it is COL3--
		fseek cf 16 #seek_cur
		if ( readLong cf == 0x334C4F43 ) then fseek cf -4 #seek_cur
		else (
			while (readLong cf != 0x334C4F43) do ()
			fseek cf -4 #seek_cur
        ) 
	) catch ( return false )
    
    return true
)--end fn findCOL3

--1----------------						--2nd UV added(19Jul05)
--Remap Tool v1.5--						--with skin data remapped--
-------------------						--Suppose SkinData is a Global Variable--
fn CondenseMtlByID obj = (
	--If not Multimaterial, quit!--
	if classof obj.material != Multimaterial then (
		return obj
	)
        
	MaxID = obj.material.count
	IDAry = #()
	for i = 1 to obj.numfaces do (
		thisID = mod (getFaceMatID obj i) MaxID
		if thisID == 0 then thisID = MaxID
		if IDAry[thisID] == undefined then IDAry[thisID] = #()
		append IDAry[thisID] i
	)--end for i
	
	CondenseAry = #()
	for i = 1 to IDAry.count do 
		if IDAry[i] != undefined then 	append CondenseAry i

	NewMtl = Multimaterial numsubs:CondenseAry.count
	for i = 1 to CondenseAry.count do (
		for j = 1 to IDAry[(CondenseAry[i])].count do
			setFaceMatID obj IDAry[(CondenseAry[i])][j] i
		NewMtl[i] = obj.material[(CondenseAry[i])]
	)
	obj.material = NewMtl
	return obj
)--end fn CondenseMtlByID

fn checkUV2mesh obj FCount = (
	try (	if obj.numTVerts == 0 then return undefined
	) catch (
		tmp = snapshot obj
		if tmp.numTVerts == 0 then ( delete tmp; return undefined )
		delete tmp
	)
	expUV2 = false
	for mdf in obj.modifiers where mdf.name == "2nd UV Map" do expUV2 = true
 --format "UV2:%\n" expUV2
	if expUV2 then (
		local msh = copy obj
		deletemodifier msh 1
		for i = 1 to obj.modifiers.count do (
			if obj.modifiers[i].name != "2nd UV Map" then deletemodifier msh 1
			else exit
		)--end for i
		convertToMesh msh
		if msh.numFaces != FCount then (
			delete msh
			return undefined
		)
		msh.transform = matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]
		return msh
	)--end if expUV2

	return undefined
	
)--end fn checkUV2mesh

fn RemapByVT msh Bmsh = (
	--Verts based--
	--===========--	
	NewUVAry = #()
	--NewVColAry = #()
	if Bmsh != undefined then NewBUVAry = #()
			
	--if (getNumCPVVerts msh) != 0 then HasVCol = true else HasVCol = false
	if (getNumCPVVerts msh) != 0 then 	NewVColAry = #() 	else 	NewVColAry = undefined

	if msh.numTVerts != 0 then (
		for i = 1 to msh.numFaces do (
			try (
				UVFace = getTVFace msh i
				VertFace = getFace msh i
				NewUVAry[VertFace.x] = getTVert msh UVFace.x
				NewUVAry[VertFace.y] = getTVert msh UVFace.y
				NewUVAry[VertFace.z] = getTVert msh UVFace.z
						
				if Bmsh != undefined then (
					if bmsh.numTVerts != 0 then (
						BUVFace = getTVFace Bmsh i
						NewBUVAry[VertFace.x] = getTVert Bmsh BUVFace.x
						NewBUVAry[VertFace.y] = getTVert Bmsh BUVFace.y
						NewBUVAry[VertFace.z] = getTVert Bmsh BUVFace.z
					) else (
						NewBUVAry[VertFace.x] = [0,0,0]
						NewBUVAry[VertFace.y] = [0,0,0]
						NewBUVAry[VertFace.z] = [0,0,0]
					)
				)
			) catch()
		)--end for i
	)--end if UV != 0
			
	if NewVColAry != undefined then (
		for i = 1 to msh.numFaces do (
			try (
				VertFace = getFace msh i
				VColFace = getVCFace msh i
				NewVColAry[VertFace.x] = getVertColor msh VColFace.x
				NewVColAry[VertFace.y] = getVertColor msh VColFace.y
				NewVColAry[VertFace.z] = getVertColor msh VColFace.z
			) catch()
		)--end for i
	)--end HasVCol
			
	-------------------------------
	--Add UV as [0,0,0]          --
	--and Dead VertColor to black--
	-------------------------------
	for j = 1 to msh.numVerts do (
		if (msh.numTVerts != 0)AND(NewUVAry[j] == undefined) then NewUVAry[j] = [0,0,0]
		if (Bmsh != undefined)AND(NewBUVAry[j] == undefined) then NewBUVAry[j] = [0,0,0]
		if (NewVColAry != undefined)AND(NewVColAry[j] == undefined) then NewVColAry[j] = color 0 0 0
	)
			
	Newmesh = snapshot msh
			
	--Set UVs--
	UV2Ary = undefined
	Newmesh.numTVerts = msh.numVerts
	buildTVFaces Newmesh
	if Bmsh != undefined then (
		for j = 1 to msh.numVerts do 	setTVert Newmesh j NewBUVAry[j]
		UV2Ary = NewUVAry	
	) else 	if msh.numTVerts != 0 then (
		for j = 1 to msh.numVerts do 	setTVert Newmesh j NewUVAry[j]
	)--end if/else 
			
	--Set VertColors--
	if NewVColAry != undefined then (
		setNumCPVVerts Newmesh msh.numVerts
		buildVCFaces Newmesh
		for j = 1 to msh.numVerts do 	setVertColor Newmesh j NewVColAry[j]
	)--end if HasVCol 	

	for j = 1 to msh.numFaces do (
		setFaceMatID Newmesh j (getFaceMatID msh j)
		if msh.numTVerts != 0 then 			setTVFace Newmesh j (getFace msh j)
		if NewVColAry != undefined then 	setVCFace Newmesh j (getTVFace msh j)
	)--end for j	
	
	delete msh
	if Bmsh != undefined then 	delete Bmsh
	return #(Newmesh, UV2Ary)
	
)--end fn RemapByVT

fn RemapByUV1 msh Bmsh SkinData = (
	if (getNumCPVVerts msh) != 0 then 	NewVColAry = #() 	else 	NewVColAry = undefined
	NewVertAry = #()
	UV2Ary = #()
	NewNormalAry = #()
	NewFaceindexAry = #()
			
	if SkinData != undefined then (
		NewBv = #()
		NewBw = #()
	)

	for i = 1 to msh.numFaces do (
		UVFace = getTVFace Bmsh i
		VertFace = getFace msh i
		NewFaceindexAry[i] = UVFace
		NewVertAry[UVFace.x] = msh.verts[VertFace.x].pos
		NewVertAry[UVFace.y] = msh.verts[VertFace.y].pos
		NewVertAry[UVFace.z] = msh.verts[VertFace.z].pos
		NewNormalAry[UVFace.x] = getNormal msh VertFace.x
		NewNormalAry[UVFace.y] = getNormal msh VertFace.y
		NewNormalAry[UVFace.z] = getNormal msh VertFace.z

		UV2Face = getTVFace msh i
		UV2Ary[UVFace.x] = getTVert msh UV2Face.x
		UV2Ary[UVFace.y] = getTVert msh UV2Face.y
		UV2Ary[UVFace.z] = getTVert msh UV2Face.z
		
		if SkinData != undefined then (
			NewBv[UVFace.x] = SkinData[1][VertFace.x]
			NewBv[UVFace.y] = SkinData[1][VertFace.y]
			NewBv[UVFace.z] = SkinData[1][VertFace.z]
			NewBw[UVFace.x] = SkinData[2][VertFace.x]
			NewBw[UVFace.y] = SkinData[2][VertFace.y]
			NewBw[UVFace.z] = SkinData[2][VertFace.z]
		)

		if NewVColAry != undefined then (
			try (
				VColFace = getVCFace msh i
				NewVColAry[UVFace.x] = getVertColor msh VColFace.x
				NewVColAry[UVFace.y] = getVertColor msh VColFace.y
				NewVColAry[UVFace.z] = getVertColor msh VColFace.z
			) catch()
		)--end HasVCol		
	
	)--end for i

	-------------------------------
	--replace Dead UV to [0,0,0] --
	--Dead Normal upward [0,0,1] --
	--and Dead VertColor to black--
	-------------------------------
	for j = 1 to NewVertAry.count do (
		if NewVertAry[j] == undefined then (
			NewVertAry[j] = [0,0,0]
			NewNormalAry[j] = [0,0,1]
		)
		if (NewVColAry != undefined)AND(NewVColAry[j] == undefined) then NewVColAry[j] = color 0 0 0
		if UV2Ary[j] == undefined then UV2Ary[j] = [0,0,0]
	)

	--rebuild mesh--
	Newmesh = mesh vertices:NewVertAry faces:NewFaceindexAry
	
	--Set UVs & Normals--
	Newmesh.numTVerts = NewVertAry.count
	buildTVFaces Newmesh
	for j = 1 to NewVertAry.count do (
		setTVert Newmesh j (getTVert Bmsh j)
		setNormal Newmesh j NewNormalAry[j]
	)
	
	--Set VertColors--
	if NewVColAry != undefined then (
		setNumCPVVerts Newmesh NewVertAry.count
		buildVCFaces Newmesh
		for j = 1 to NewVertAry.count do 	setVertColor Newmesh j NewVColAry[j]
	)--end if HasVCol 

	for j = 1 to msh.numFaces do (
		setTVFace Newmesh j (getTVFace Bmsh j)
		setFaceMatID Newmesh j (getFaceMatID msh j)
		if NewVColAry != undefined then  setVCFace Newmesh j (getTVFace msh j)
	)--end for j

	if SkinData != undefined then  SkinData2 = #(NewBv,NewBw,SkinData[3])
	
	delete msh
	delete Bmsh
	return #(Newmesh, UV2Ary,SkinData2)

)--end fn RemapByUV1

fn RemapByUV2 msh Bmsh SkinData = (
	if (getNumCPVVerts msh) != 0 then 	NewVColAry = #() 	else 	NewVColAry = undefined
	if Bmsh != undefined then 			NewBUVAry = #() 	else 	NewBUVAry = undefined
	NewVertAry = #()
	NewNormalAry = #()
	NewFaceindexAry = #()
			
	if SkinData != undefined then (
		NewBv = #()
		NewBw = #()
	)

	for i = 1 to msh.numFaces do (
		UVFace = getTVFace msh i
		VertFace = getFace msh i
		NewFaceindexAry[i] = UVFace
		NewVertAry[UVFace.x] = msh.verts[VertFace.x].pos
		NewVertAry[UVFace.y] = msh.verts[VertFace.y].pos
		NewVertAry[UVFace.z] = msh.verts[VertFace.z].pos
		NewNormalAry[UVFace.x] = getNormal msh VertFace.x
		NewNormalAry[UVFace.y] = getNormal msh VertFace.y
		NewNormalAry[UVFace.z] = getNormal msh VertFace.z

		if Bmsh != undefined then (
			if Bmsh.numTVerts != 0 then (
				BUVFace = getTVFace Bmsh i
				NewBUVAry[UVFace.x] = getTVert Bmsh BUVFace.x
				NewBUVAry[UVFace.y] = getTVert Bmsh BUVFace.y
				NewBUVAry[UVFace.z] = getTVert Bmsh BUVFace.z
			) else (
				NewBUVAry[UVFace.x] = [0,0,0]
				NewBUVAry[UVFace.y] = [0,0,0]
				NewBUVAry[UVFace.z] = [0,0,0]			
			)
		)

		if SkinData != undefined then (
			NewBv[UVFace.x] = SkinData[1][VertFace.x]
			NewBv[UVFace.y] = SkinData[1][VertFace.y]
			NewBv[UVFace.z] = SkinData[1][VertFace.z]
			NewBw[UVFace.x] = SkinData[2][VertFace.x]
			NewBw[UVFace.y] = SkinData[2][VertFace.y]
			NewBw[UVFace.z] = SkinData[2][VertFace.z]
		)

		if NewVColAry != undefined then (
			try (
				VColFace = getVCFace msh i
				NewVColAry[UVFace.x] = getVertColor msh VColFace.x
				NewVColAry[UVFace.y] = getVertColor msh VColFace.y
				NewVColAry[UVFace.z] = getVertColor msh VColFace.z
			) catch()
		)--end HasVCol		
	
	)--end for i

	-------------------------------
	--replace Dead UV to [0,0,0] --
	--Dead Normal upward [0,0,1] --
	--and Dead VertColor to black--
	-------------------------------
	for j = 1 to NewVertAry.count do (
		if NewVertAry[j] == undefined then (
			NewVertAry[j] = [0,0,0]
			NewNormalAry[j] = [0,0,1]
		)
		if (NewVColAry != undefined)AND(NewVColAry[j] == undefined) then NewVColAry[j] = color 0 0 0
		if (Bmsh != undefined)AND(NewBUVAry[j] == undefined) then NewBUVAry[j] = [0,0,0]
	)

	--rebuild mesh--
	Newmesh = mesh vertices:NewVertAry faces:NewFaceindexAry
	
	--Set UVs & Normals--
	UV2Ary = undefined
	Newmesh.numTVerts = NewVertAry.count
	buildTVFaces Newmesh
	if Bmsh != undefined then (
		UV2Ary = #()
		for j = 1 to NewVertAry.count do (
			setTVert Newmesh j NewBUVAry[j]
			setNormal Newmesh j NewNormalAry[j]
			append UV2Ary (getTVert msh j)
		)
	) else (
		for j = 1 to NewVertAry.count do (
			setTVert Newmesh j (getTVert msh j)
			setNormal Newmesh j NewNormalAry[j]
		)
	)
	
	--Set VertColors--
	if NewVColAry != undefined then (
		setNumCPVVerts Newmesh NewVertAry.count
		buildVCFaces Newmesh
		for j = 1 to NewVertAry.count do 	setVertColor Newmesh j NewVColAry[j]
	)--end if HasVCol 

	for j = 1 to msh.numFaces do (
		setTVFace Newmesh j (getTVFace msh j)
		setFaceMatID Newmesh j (getFaceMatID msh j)
		if NewVColAry != undefined then  setVCFace Newmesh j (getTVFace msh j)
	)--end for j

	if SkinData != undefined then  (
        SkinData2 = #(NewBv,NewBw,SkinData[3])
 --format "SkinData2:%\n" SkinData2[1].count
	)
    
	delete msh
	if Bmsh != undefined then 	delete Bmsh
	return #(Newmesh, UV2Ary, SkinData2)

)--end fn RemapByUV2

fn RemapGeo obj SkinData = (						-- 18Jul05 10:16am --
	try (
	bkTrans = obj.transform
	msh = snapshot obj
 --format "msh(%)\n" msh.numTVerts
	msh.transform = matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]
	Bmsh = checkUV2mesh obj msh.numFaces
	
	if (msh.numTVerts == 0)AND(Bmsh == undefined) then 	tmp = #(msh)
	else (
	
 --z = 0;format "Bmsh:%(%)\n" Bmsh (try(Bmsh.numTVerts)catch(z))
 --format "msh(%)\n" msh.numTVerts

		nVTs = msh.numVerts
		nUV2 = msh.numTVerts
		if Bmsh != undefined then nUV1 = Bmsh.numTVerts else nUV1 = -1
 --format "nVTs:%\tnUV1:%\tnUV2:%\t\n" nVTs nUV1 nUV2
		Rult = nVTs
		if nUV2 > Rult then Rult = nUV2
		if nUV1 > Rult then Rult = nUV1
 --format "->%\n" Rult
		tmp = case Rult of (
			nVTs: RemapByVT msh Bmsh 
			nUV2: RemapByUV2 msh Bmsh SkinData
			nUV1: RemapByUV1 msh Bmsh SkinData
		)	

	)
	Newmesh = tmp[1]
	Newmesh.transform = bkTrans
	Newmesh.name = obj.name + "_remap"
	Newmesh.material = obj.material
	Newmesh.wirecolor = obj.wirecolor
        
	--	format "Remapped: %\nVerts: %\tUVs: %\tVCol: %\n" Newmesh.name Newmesh.numVerts Newmesh.numTVerts (getNumCPVVerts Newmesh)
	
	)catch(delete msh; format "Geometry: %  is not supported\n" obj.name; return undefined)

	return #(Newmesh,tmp[2],tmp[3])

)--end fn RemapGeo


--2---------------
--Frame Function--
------------------
fn CreateFrameMatrices bonechain = (
	fmx = #()
	for i = 1 to bonechain.count do (
		try (
			tmp = bonechain[i].transform * inverse (bonechain[i].parent.transform)
		) catch (
			tmp = bonechain[i].transform * inverse ( matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0] )
		)
--format "%\t%\n" bonechain[i].name tmp
		append fmx tmp
	)
	return fmx
)--end fn CreateFrameMatrices


--3---------------
--Bones Function--
------------------
fn IndexBoneOrder objset = (
	HieAry = #()
	idx = 0
	while idx < objset.count do (
		for b in objset do (
			if (getUserProp b "BoneIndex") == idx then (
--format "->% =>%\n" b.name idx
				append HieAry b
				idx += 1
				exit
			)--end if
		)--end for 
	)--end while
--format "HieAry:%\n" 	HieAry
	return HieAry

)--end fn IndexBoneOrder

fn CreateBoneOrder objset = (
	HieAry = #()
for aa = 1 to objset.count do format "%\n" objset[aa].name
	local thisbase
	--Get Root--
	for obj in objset where (finditem objset obj.parent == 0) do (thisbase = obj)
format "Root: %\n" thisbase.name
	append HieAry thisbase
	--Loop--
	doloop = true
	branch = #()
	while doloop == true do (
		tmp =  thisbase.children
		if (tmp.count == 0) then (
			if branch.count == 0 then doloop = false
			else (
				idx = branch[branch.count]
		--		format "idx:%\n" idx
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

	return HieAry
	
)--end fn CreateBoneOrder	--<B1>--


fn CreateInvBoneMatrices chain = (
	InvBoneMatrices = #()
	p0 = matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]
	for i = 1 to chain.count do (
		try (
			tmp = chain[i].transform * inverse (chain[i].parent.transform)
		) catch (
			tmp = chain[i].transform * inverse ( matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0] )
		)
		parentindex = finditem chain chain[i].parent
		if parentindex == 0 then append InvBoneMatrices ( p0 * inverse (tmp) )        
		else append InvBoneMatrices ( InvBoneMatrices[parentindex] * inverse (tmp) )
--		else append InvBoneMatrices ( bonechain[i].transform * inverse (bonechain[i].parent.transform) )
	)--end for i
	   
	return InvBoneMatrices
	
)--fn invBoneMx				--<B2>--


--4--------------
--Skin Function--
-----------------
fn sortBybw bv bw = (
	for i = bw.count to 2 by -1 do (
		if bw[i] > bw[(i-1)] then (
			swap bw[i] bw[(i-1)]
			swap bv[i] bv[(i-1)]
		) else exit
	)
	if bw.count == 5 then (
		deleteitem bw 5
		deleteitem bv 5
	)
	
	return #(bv,bw)
	
)--end fn sortBybw			--<s1>--


fn CreateSkinData obj = (
	global skn = obj.modifiers[1]
	skn;skinops
	totalVerts = skinOps.getNumberVertices skn
	bvAry = #()
	bwAry = #()
--New Edit (18Jul05)--**
	spBoneAry = #()
--**
	for i = 1 to totalVerts do (
		infbones = skinOps.GetVertexWeightCount skn i
--format "Catch you V:%\tno.bones:%\n" i infbones
	--	bv = #( ((skinOps.GetVertexWeightBoneID skn i 1)-1) )
		bid = skinOps.GetVertexWeightBoneID skn i 1
		bname = skinOps.GetBoneName skn bid 0
 		tt = "getUserProp $'" + bname + "' \"BoneIndex\""
		idx = execute tt
		bv = #( idx )

		bw = #( (skinOps.GetVertexWeight skn i 1) )
		for j = 2 to infbones do (
	--		append bv ((skinOps.GetVertexWeightBoneID skn i j)-1)
			bid = skinOps.GetVertexWeightBoneID skn i j
			bname = skinOps.GetBoneName skn bid 0
 			tt = "getUserProp $'" + bname + "' \"BoneIndex\""
			idx = execute tt
			append bv idx

			append bw (skinOps.GetVertexWeight skn i j)
			tmp = sortBybw bv bw
			bv = tmp[1]
			bw = tmp[2]
		)--end for j

		--normalize boneweight if influencing bones more than 4
		-------------------------------------------------------
		if infbones > 4 then (
			infactor = 1 / ( bw[1] + bw[2] + bw[3] + bw[4] )
			for j = 1 to 4 do bw[j] *= infactor
		)
	
		--Root bone must be the last one in array
		-----------------------------------------
		fr = finditem bv 0 
		if fr != 0 then (
			swap bv[fr] bv[(bv.count)]
			swap bw[fr] bw[(bv.count)]
		)
	
		--fill up arrays to 4 bone spaces
		---------------------------------
		for k = (bv.count+1) to 4 do (
			append bv 0
			append bw 0
		)
	
		append bvAry bv
		append bwAry bw
        
--New Edit(18Jul05)--**
		for id in bv where id != 0 do spBoneAry[id] = id
		for i = spBoneAry.count to 1  by -1 do if  spBoneAry[i] == undefined then deleteitem spBoneAry i
--**
	)--end for i

--format "spBoneAry:%\n" spBoneAry

--New Edit(18Jul05)--**
	return #(bvAry,bwAry,spBoneAry)
--**
)--end fn CreateSkinData	--<s2>--


--5-----------------------
-- Functions for Export --
--------------------------
fn wClump f object_count ver = (
	WriteLong f 0x10						-- rwClump
	WriteLong f 0							-- temp for clump size
	WriteLong f ver							-- file version for GTA3
	--DATA--
	WriteLong f 0x01						-- rwData
	if (ver == 0x0800FFFF)OR(ver == 0x00000310) then (
		WriteLong f	4
		WriteLong f ver						-- file version for GTA3
		WriteLong f object_count
	) else (
		WriteLong f	12
		WriteLong f ver						-- file version for GTA3
		WriteLong f object_count
		WriteLong f 0; WriteLong f 0
	)
)--end fn wClump				--<e1>--


fn wFrameList f Allobjects Iscale ver = (
	tmp = Allobjects as array
	writeLong f 0x0E							-- rwFrameList
	FL_length_add = ftell f
	writeLong f 0								-- temp for clump size
	writeLong f ver								-- file version for GTA3
    
	writeLong f 0x01							-- rwData
	writeLong f ( tmp.count * 56 + 4 )
	writeLong f ver								-- file version for GTA3
	writeLong f tmp.count
	for i = 1 to tmp.count do (
		if tmp[i].parent != undefined then (
			bkup = tmp[i].parent.transform
			tmp[i].parent.transform = (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
			tfm = tmp[i].transform
			tmp[i].parent.transform = bkup
		) else ( 
			tfm = matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]
 --format "Root->%\n" tmp[i].name
		)
		writeFloat f tfm.row1.x
		writeFloat f tfm.row1.y
		writeFloat f tfm.row1.z
		writeFloat f tfm.row2.x
		writeFloat f tfm.row2.y
		writeFloat f tfm.row2.z
		writeFloat f tfm.row3.x
		writeFloat f tfm.row3.y
		writeFloat f tfm.row3.z
		tpos = tfm.row4 * Iscale
		writeFloat f tpos.x
		writeFloat f tpos.y
		writeFloat f tpos.z
		writeLong f ( finditem tmp tmp[i].parent - 1 )
		if tmp[i].parent != undefined then writeLong f 3
		else writeLong f 131075
	)--end for i
	for i = 1 to tmp.count do (
		WriteLong f 0x03						--rwExtension
		WriteLong f ( tmp[i].name.count + 12 )
		WriteLong f ver							-- file version for GTA3
		WriteLong f 0x0253F2FE					--rwFrame  39056126
		WriteLong f ( tmp[i].name.count )
		WriteLong f ver							-- file version for GTA3
		writeString f tmp[i].name
		fseek f -1 #seek_cur
	)--end for i
	local here = ftell f
	FL_length = here - 8 - FL_length_add
	fseek f FL_length_add #seek_set
	WriteLong f FL_length
	fseek f here #seek_set
)--end fn wFrameList			--<e2>--


fn wAtomic f Fidx Gidx ver noCol = (						-- 03Dec04 11:55am --
    writeLong f 0x14						-- rwAtomic
--New Edit(14Jul05)(08Aug08)--***
		if (ver == 0X1803FFFF) then (
			atmbyte = case noCol of (
				0: 76
				1: 40
				2: 92
			)
			writeLong f atmbyte
		) else writeLong f 56					-- fixed for GTA3/VC
--***	
	WriteLong f ver							-- file version for GTA3
    writeLong f 1
	writeLong f 16							-- fixed for GTA3
	WriteLong f ver							-- file version for GTA3
	writeLong f (Fidx - 1)
	writeLong f (Gidx - 1)
	writeLong f 5							-- unknown??
	writeLong f 0							-- unknown??
	writeLong f 3							-- rwExtension
--New Edit(09Jul05)(08Aug05)--***
	if (ver == 0X1803FFFF) then (
		extbyte = case noCol of (
			0: 36
			1: 0
			2: 52
		)
		writeLong f extbyte
		writeLong f ver
		if noCol != 1 then (
			writeLong f 0x1F					--Right To Render
			writeLong f 8
			writeLong f ver
			writeLong f 0X120
			writeLong f 0
        )
	) else (
		writeLong f 16							-- fixed for GTA3/VC
		writeLong f ver							-- file version for GTA3
	)
--New Edit(14Jul05)(08Aug05)--***
	if (ver != 0x1803FFFF)OR(noCol != 1) then (
		writeLong f 0x120						-- rwMaterialEffectPLG
		writeLong f 4							-- fixed for GTA3
		WriteLong f ver							-- file version for GTA3
		--if ver == 0X1803FFFF then writeLong f 1
		--else writeLong f 0					-- fixed for GTA3/VC
		writeLong f 1
	)
	if (ver == 0x1803FFFF)AND(noCol == 2) then (
		writeLong f 0x253F2F3						-- rwMaterialEffectPLG
		writeLong f 4							-- fixed for GTA3
		WriteLong f ver							-- file version for GTA3    
		writeLong f 0x53F2009A   
	)
--**
)--end fn wAtomic				--<e3>--


fn wGeometryList f Allobjects ver = (
    geo = for obj in Allobjects where superclassof obj == geometryClass collect obj
    writeLong f 0x1A						-- rwGeometryList
	GL_length_add = ftell f
	writeLong f 0							-- temp for GeometryList size
	WriteLong f ver							-- file version for GTA3
	writeLong f 1							-- rwData
	writeLong f 4
 	WriteLong f ver							-- file version for GTA3
	writeLong f geo.count
	return GL_length_add
)--end fn wGeometryList			--<e4>--


fn wMaterialSplit f msh ver = (						-- 22Dec04 4:43pm --
	writeLong f 0x050E						-- rwMatrialSplit
	MSplt_length_add = ftell f
	writeLong f 0							-- temp for MaterialSplit size
	WriteLong f ver							-- file version for GTA3
	
	local FIDAry = #()
	if classof msh.material != Multimaterial then (
		FIDAry[1] = #()
		for i = 1 to msh.numfaces do append FIDAry[1] i
	) else (
		for i = 1 to msh.material.count do FIDAry[i] = #()
 	    for i = 1 to msh.numfaces do (
        	id = mod (getfaceMatid msh i) msh.material.count
			if id == 0 then id = msh.material.count
	        append FIDAry[id] i
    	)--end for i
	)--end if/else
    writeLong f 0							--Split Type
    writeLong f FIDAry.count
    writeLong f (msh.numfaces * 3)
    for i = 1 to FIDAry.count do (
        writeLong f (FIDAry[i].count * 3)
        writeLong f (i - 1)
        for j = 1 to FIDAry[i].count do (
            local tmp = getFace msh FIDAry[i][j]
    		writeLong f (tmp.x - 1)
            writeLong f (tmp.y - 1)
            writeLong f (tmp.z - 1)
        )--end for j
    )--end for i
	local here = ftell f
	MSplt_length = here - 8 - MSplt_length_add
	fseek f MSplt_length_add #seek_set
	writeLong f MSplt_length
	fseek f here #seek_set
)--end fn wMaterialSplit		--<e5>--


fn wTexture f mtl isreflection ver = ( 
    writeLong f 0x06						-- rwTexture
	T_length_add = ftell f
	writeLong f 0							-- temp for Material size
	WriteLong f ver							-- file version for GTA3
	writeLong f 1
	writeLong f 4							-- Data size (filter flag, unknown)
	WriteLong f ver							-- file version for GTA3   

	if isreflection == true then (
		tname = getFilenameFile mtl.reflectionMap.filename
		Filtertype = mtl.reflectionMap.filtering
		mname = ""
	) else (
--New Edit(06Jul05)--**
		if classof mtl == GTA_Mtl then (
			if (classof mtl.alphamap == Bitmaptexture)AND(mtl.use_alphamap == true) then (
				mname = getFilenameFile mtl.alphamap.filename
				Filtertype = mtl.alphamap.filtering
			) else mname = ""        
			if (classof mtl.colormap == Bitmaptexture)AND(mtl.use_colormap == true) then (
				tname = getFilenameFile mtl.colormap.filename
				Filtertype = mtl.colormap.filtering
			) else tname = ""
        ) else (
			if (classof mtl.opacitymap == Bitmaptexture)AND(mtl.opacityMapEnable == true) then (
				mname = getFilenameFile mtl.opacitymap.filename
				Filtertype = mtl.opacitymap.filtering
			) else mname = ""
			if (classof mtl.diffusemap == Bitmaptexture)AND(mtl.diffuseMapEnable == true) then (
				tname = getFilenameFile mtl.diffusemap.filename
				Filtertype = mtl.diffusemap.filtering
			) else tname = ""
		)--end if/else GTA_mtl
--**
	)
	case FilterType of (
		0: writeShort f 0x106
		1: writeShort f 0x102
		2: writeShort f 0x101
		default: writeShort f 0x1102
	)--end case

--New Edit--***
	if ver == 0X1803FFFF then writeShort f 1
		else writeShort f 0
--***

	local noffset = mod (tname.count + 1) 4
	if noffset != 0 then  nc = ((tname.count + 1)/4 + 1) * 4
	else  nc = tname.count + 1

	writeLong f 0x02						-- rwString
	writeLong f nc
	WriteLong f ver							-- file version for GTA3    
	writeString f tname
    
	if noffset != 0 then (
		for i = 1 to (4 - noffset) do 
			writeByte f 0
	)
    
	local noffset = mod (mname.count + 1) 4
	if noffset != 0 then  nc = ((mname.count + 1)/4 + 1) * 4
	else  nc = mname.count + 1
    
	writeLong f 0x02						-- rwString
	writeLong f nc
	writeLong f ver							-- file version for GTA3    
	writeString f mname
    
	if noffset != 0 then (
		for i = 1 to (4 - noffset) do 
			writeByte f 0
	)
    
	writeLong f 3
	writeLong f 0
	writeLong f ver							-- file version for GTA3 
	local here = ftell f
	T_length = here - 8 - T_length_add
	fseek f T_length_add #seek_set
	writeLong f T_length
	fseek f here #seek_set  
)--end fn wTexture				--<e6>--


fn wMaterial f msh mtl ver = (
	writeLong f 0x07						-- rwMaterial
	M_length_add = ftell f
	writeLong f 0							-- temp for Material size
	WriteLong f ver							-- file version for GTA3
	writeLong f 1							-- rwData
	writeLong f 28							-- Data size (material_count, unknown)
 	WriteLong f ver							-- file version for GTA3 
	writeLong f 0							--unknown??
--New Edit(06Jul05)--**
	if mtl != undefined then (
		if classof mtl == GTA_Mtl then (
			writeByte f mtl.color.r
			writeByte f mtl.color.g
			writeByte f mtl.color.b
			writeByte f mtl.alpha
			if ver == 0X1803FFFF then writeLong f 16688092
			else writeLong f 1629820					--unknown??
			if (classof mtl.colormap == Bitmaptexture)AND(mtl.use_colorMap == true) \
						OR(classof mtl.alphamap == Bitmaptexture)AND(mtl.use_alphamap == true) \
						then	writeLong f 1
			else writeLong f 0
			writeFloat f mtl.amb
			writeFloat f mtl.spc
			writeFloat f mtl.dif
			if (classof mtl.colormap == Bitmaptexture)AND(mtl.use_colorMap == true) \
						OR(classof mtl.alphamap == Bitmaptexture)AND(mtl.use_alphamap == true) \
						then 		wTexture f mtl false ver
		) else (
			writeByte f (mtl.diffuse.r as integer) 
			writeByte f (mtl.diffuse.g as integer)
			writeByte f (mtl.diffuse.b as integer)
			writeByte f ((mtl.opacity/100 * 255.0) as integer) #unsigned
			if ver == 0X1803FFFF then writeLong f 16688092
			else writeLong f 1629820					--unknown??
			--texture_count--
			if (classof mtl.diffusemap == Bitmaptexture)AND(mtl.diffuseMapEnable == true) \
						OR(classof mtl.opacitymap == Bitmaptexture)AND(mtl.opacityMapEnable == true) \
						then	writeLong f 1
			else writeLong f 0
			writeFloat f 1.0					--unknown??
			writeFloat f (mtl.specular_level / 100.0)
			writeFloat f 1.0					--unknown??
			if (classof mtl.diffusemap == Bitmaptexture)AND(mtl.diffuseMapEnable == true) \
						OR(classof mtl.opacitymap == Bitmaptexture)AND(mtl.opacityMapEnable == true) \
						then 		wTexture f mtl false ver
		)
            
--New Edit--***
		writeLong f 3					-- rwExtension
		MatExt_Length_add = ftell f
		writeLong f 0					-- temp for Material extension size
		writeLong f ver					-- file version for GTA3
        
		--Reflection--
        expReflection = false
		if (classof mtl == GTA_Mtl)AND(mtl.use_RF == true) then (
			if (ver == 0X1803FFFF)AND((classof mtl.reflectionmap != Bitmaptexture)OR(mtl.use_reflectionmap == false)) then (
                writeLong f 0x0120
                writeLong f 24
                writeLong f ver
                writeLong f 2
                writeLong f 2
                writeFloat f (mtl.Reflection/100)
                writeLong f 0
                writeLong f 0
                writeLong f 0
            ) else if ((classof mtl.reflectionmap == Bitmaptexture)AND(mtl.use_reflectionmap == true)) then expReflection = true
		) else if (classof mtl == standardmaterial)AND(mtl.reflectionMapEnable==true)AND(classof mtl.reflectionmap == Bitmaptexture) then expReflection = true
		if expReflection  == true then (

			writeLong f 0x0120				--Material Effects PLG
			matEffPLG_Length_add = ftell f
			writeLong f 0					-- temp for Material Effects PLG size
			writeLong f ver					-- file version for GTA3			

			writeLong f 2;writeLong f 2		-- unknown
			if classof mtl == GTA_Mtl then writeFloat f (mtl.Reflection/100)
			else writeFloat f (mtl.reflectionmapamount/100.0)
			writeLong f 0;writeLong f 1		-- unknown

			wTexture f mtl true ver
			writeLong f 0					-- ??
			
			here = ftell f
			fseek f matEffPLG_Length_add #seek_set
			writeLong f (here - matEffPLG_Length_add - 8)
			fseek f here #seek_set

		) 
		--RefMat--
		if (ver == 0X1803FFFF) then (
			expRefMat = false
			if (classof mtl == GTA_Mtl)AND(mtl.use_SAS == true) then expRefMat = true
			else if (classof mtl == standardmaterial)AND(mtl.specular != (color 0 0 0)) then expRefMat = true
			if expRefMat == true then (
				writeLong f 0x0253F2FC				--RefMat
				writeLong f 24
				writeLong f ver					-- file version for GTA3	
				writeFloat f (mtl.specular.r/255.0)
				writeFloat f (mtl.specular.g/255.0)
				writeFloat f (mtl.specular.b/255.0)
            
				if classof mtl == GTA_Mtl then (
					writeFloat f (mtl.spec_alpha/255.0)
					writeFloat f mtl.blend
				) else (
					writeFloat f 1
					bnd = mtl.glossiness + mtl.soften
					writeFloat f bnd
				)
				writeFloat f 0
            )
		)
		
        --SpecMat???--
		if (ver == 0X1803FFFF) then (
			expSpecMat = false
			if (classof mtl == GTA_Mtl)AND(mtl.use_SI == true) then expSpecMat = true
			else if (classof mtl == standardmaterial)AND(classof mtl.SpecularMap == Bitmaptexture)AND(mtl.SpecularMapEnable == true) then expSpecMat = true
			if expSpecMat == true then (
				writeLong f 0x0253F2F6				--Unknown??
				writeLong f 28					-- ??
				writeLong f ver					-- file version for GTA3
 				if classof mtl == GTA_Mtl then writeFloat f (mtl.spec_power/100)
 				else 		writeFloat f (mtl.Specular_level/100.0)
 				try (SPname = getFilenameFile mtl.SpecularMap.filename)catch(SPname = " ")
 				if SPname.count >23 then SPname = substring SPname 1 23
            	writeString f SPname
            	for ii = 1 to (23 - SPname.count) do ( writeByte f 0 )
			)
		)

		--End of Material Extension--
		here = ftell f
		fseek f MatExt_Length_add #seek_set
		writeLong f (here - MatExt_Length_add - 8)
		fseek f here #seek_set
        
	) else (                    -- if no material assigned
		writeByte f ((msh.wirecolor.r) as integer)
		writeByte f ((msh.wirecolor.g) as integer)
		writeByte f ((msh.wirecolor.b) as integer)
		writeByte f 255
--New Edit--***
		if ver == 0X1803FFFF then writeLong f 16688092
		else writeLong f 1629820					--unknown??
--***
		writeLong f 0
		writeFloat f 1.0					--unknown??
		writeFloat f 0.05
		writeFloat f 1.0					--unknown??
		writeLong f 0x03					-- rwExtension
		writeLong f 0						-- Data size (material_count, unknown)
		writeLong f ver						-- file version for GTA3 
	)

	local here = ftell f
	M_length = here - 8 - M_length_add
	fseek f M_length_add #seek_set
	writeLong f M_length
	fseek f here #seek_set 
)--end fn wMaterial				--<e7>--


fn wMaterialList f msh ver = (
    writeLong f 0x08						-- rwMaterialList
	ML_length_add = ftell f
	writeLong f 0							-- temp for MaterialList size
	WriteLong f ver							-- file version for GTA3
	writeLong f 0x01						-- rwData
    if classof msh.material != MultiMaterial then (
        writeLong f 8						-- Data size (material_count, unknown)
 	    WriteLong f ver						-- file version for GTA3 
        writeLong f 1
        writeLong f -1						--unknown??
        wMaterial f msh msh.material ver
    ) else (
        local DataSize = (1 + msh.material.count) * 4
 	    writeLong f DataSize				-- Data size (material_count, unknown)
        WriteLong f ver						-- file version for GTA3 
        writeLong f (msh.material.count)
		for i = 1 to msh.material.count do 
  		      writeLong f -1				--unknown??
        for i = 1 to msh.material.count do (
            wMaterial f msh msh.material[i] ver
        )
    )--end if/else
    local here = ftell f
	ML_length = here - 8 - ML_length_add
	fseek f ML_length_add #seek_set
	writeLong f ML_length
	fseek f here #seek_set
)--end fn wMaterialList			--<e8>--


fn wSkinFrameList f bonechain Iscale ver = (		-- 19Jan05 9:03am --
	writeLong f 0x0E						-- rwFrameList
	FL_length_add = ftell f
	writeLong f 0							-- temp for clump size
	writeLong f ver							-- file version for GTA3
	writeLong f 1
	writeLong f ( (bonechain.count + 1) * 56 + 4 )
	writeLong f ver							-- file version for GTA3
	
	writeLong f (bonechain.count + 1)
	
	--export Mesh transform--
	tfm = $.transform
	writeFloat f tfm.row1.x
	writeFloat f tfm.row1.y
	writeFloat f tfm.row1.z
	writeFloat f tfm.row2.x
	writeFloat f tfm.row2.y
	writeFloat f tfm.row2.z
	writeFloat f tfm.row3.x
	writeFloat f tfm.row3.y
	writeFloat f tfm.row3.z
	tpos = tfm.row4 * Iscale
	writeFloat f tpos.x
	writeFloat f tpos.y
	writeFloat f tpos.z
	writeLong f -1
	writeLong f 131075
	
	--export Bones transform--	
	FrameMatrices = CreateFrameMatrices bonechain
--format "FrameMatrices Count:%\n" FrameMatrices.count
	for i = 1 to FrameMatrices.count do (
		tfm = FrameMatrices[i]
		writeFloat f tfm.row1.x
		writeFloat f tfm.row1.y
		writeFloat f tfm.row1.z
		writeFloat f tfm.row2.x
		writeFloat f tfm.row2.y
		writeFloat f tfm.row2.z
		writeFloat f tfm.row3.x
		writeFloat f tfm.row3.y
		writeFloat f tfm.row3.z
		tfm.row4 * Iscale
		writeFloat f tfm.row4.x
		writeFloat f tfm.row4.y
		writeFloat f tfm.row4.z
		pf = (finditem bonechain bonechain[i].parent)
--format "%: Parent Frame:%\n" i pf
		writeLong f pf
		writeLong f 0
	)--end for i
	
	--Mesh Frame--
--New Edit(12Jul05)--**
	if ver != 0x1803FFFF then (
		WriteLong f 3						-- rwExtension
		WriteLong f ( $.name.count + 36 )
		WriteLong f ver						-- file version for GTA3	

		WriteLong f 0x0253F2FE				-- rwFrame 39056126
		WriteLong f ( $.name.count )	
		WriteLong f ver
		writeString f $.name
		fseek f -1 #seek_cur	

		WriteLong f 0x011E					-- rwHAnimPLG
		WriteLong f 12	
		WriteLong f ver	
		WriteLong f 256
		WriteLong f -1
		WriteLong f 0
	) else (
		WriteLong f 3						-- rwExtension
		WriteLong f 0
		WriteLong f ver    
	)
--**
	--Bone Frame--
	for i = 1 to bonechain.count do (
		if (finditem bonechain bonechain[i].parent) != 0 then (
			--child bone--
			WriteLong f 3
			WriteLong f ( bonechain[i].name.count + 36 )
			WriteLong f ver				-- file version for GTA3			

			WriteLong f 0x0253F2FE		-- rwFrame 39056126
			WriteLong f ( bonechain[i].name.count )	
			WriteLong f ver
			writeString f bonechain[i].name
			fseek f -1 #seek_cur

			WriteLong f 0x011E			-- rwHAnimPLG
			WriteLong f 12	
			WriteLong f ver	
			WriteLong f 256
			WriteLong f (getUserProp bonechain[i] "BoneID")
			WriteLong f 0
		) else (
--format "::%\tparent:%\n" bonechain[i].name bonechain[i].parent
			--Root bone--
			WriteLong f 3
			WriteLong f ( bonechain[i].name.count + 24 + (((bonechain.count)*3+5)*4) )
			WriteLong f ver				-- file version for GTA3		

			WriteLong f 0x0253F2FE		-- rwFrame 39056126
			WriteLong f ( bonechain[i].name.count )	
			WriteLong f ver
			writeString f bonechain[i].name
			fseek f -1 #seek_cur

			indexedOrder = IndexBoneOrder bonechain   
        
			WriteLong f 0x011E			-- rwHAnimPLG
			WriteLong f (((indexedOrder.count*3)+5)*4)	
			WriteLong f ver	
			WriteLong f 256
			WriteLong f (getUserProp indexedOrder[i] "BoneID")
			WriteLong f (indexedOrder.count)
			WriteLong f 0
			WriteLong f 36      

			for jj = 1 to indexedOrder.count do (
				WriteLong f (getUserProp indexedOrder[jj] "BoneID")
				WriteLong f (jj - 1)
				WriteLong f (getUserProp indexedOrder[jj] "BoneType")
			)--end for jj
		)--end if/else	
	)--end for i
	
	local here = ftell f
	FL_length = here - 8 - FL_length_add
	fseek f FL_length_add #seek_set
	WriteLong f FL_length
	fseek f here #seek_set
)--end fn wFrameList			--<e9>--


fn wSkinAtomic f Fidx Gidx ver = (					-- 18Jan05 4:51pm --
    writeLong f 0x14
--New Edit(12Jul05)--**
	if ver == 0x1803FFFF then writeLong f 60
	else writeLong f 76			-- fixed for GTA3
--**
	WriteLong f ver			-- file version for GTA3
    writeLong f 1
	writeLong f 16			-- fixed for GTA3
	WriteLong f ver			-- file version for GTA3
    writeLong f (Fidx - 1)
    writeLong f (Gidx - 1)
    writeLong f 5           --unknown??
    writeLong f 0           --unknown??
	
	--extension--
    writeLong f 3
--New Edit(12Jul05)--**
	if ver == 0x1803FFFF then writeLong f 20
	else writeLong f 36			-- fixed for GTA3
--**
	WriteLong f ver			-- file version for GTA3

--Right to Render--
    writeLong f 0x1F		
	writeLong f 8			-- fixed for GTA3
	WriteLong f ver			-- file version for GTA3
	writeLong f 0x116	
	writeLong f 1

--New Edit(12Jul05)--**
	if ver != 0x1803FFFF then (
		--Material Effect PLG--
		writeLong f 0x120		
		writeLong f 4			-- fixed for GTA3
		WriteLong f ver			-- file version for GTA3
    	writeLong f 0
	)
--**
)--end fn wAtomic				--<e10>--


fn wSkinPlg f SkinData bonechain Iscale ver = (		-- 19Jan05 9:31am --
--format "4:SkinData:%\n" SkinData[1].count

--New Edit(08Jul05)(18Jul05)--**
    if ver == 0x1803FFFF then skinPlg_size = (SkinData[1].count * 20) + (bonechain.count * 64) + 16 + SkinData[3].count
	else skinPlg_size = (SkinData[1].count * 20) + (bonechain.count * 68) + 4
--**
	writeLong f 0x116                       --Skin PLG
	writeLong f skinPlg_size
	writeLong f ver
	
--New Edit(18Jul05)--**
	if ver == 0x1803FFFF then (
		writeByte f bonechain.count
		writeByte f SkinData[3].count
		writeShort f 0
		for id in SkinData[3] do writeByte f id 
	) else writeLong f bonechain.count
--**
--format "Verts:%\n"  SkinData[1].count
	for i = 1 to SkinData[1].count do (
		writeByte f SkinData[1][i][1]
		writeByte f SkinData[1][i][2]
		writeByte f SkinData[1][i][3]
		writeByte f SkinData[1][i][4]
	)--end for i
    
	for i = 1 to SkinData[2].count do (
		writeFloat f SkinData[2][i][1]
		writeFloat f SkinData[2][i][2]
		writeFloat f SkinData[2][i][3]
		writeFloat f SkinData[2][i][4]
	)--end for i

    IndexChain = IndexBoneOrder bonechain
--for xyxy in IndexChain do ( format ">>%\n" xyxy.name )
    ibm = CreateInvBoneMatrices IndexChain
	for jj = 1 to ibm.count do (
		tfm = ibm[jj]
--New Edit(08Jul05)--**
        if ver != 0x1803FFFF then (
		    writeShort f 0xDEAD
		    writeShort f 0xDEAD
        ) 
--**
		writeFloat f tfm.row1.x
		writeFloat f tfm.row1.y
		writeFloat f tfm.row1.z
		writeFloat f 0                      --unknown ?? Testing
		writeFloat f tfm.row2.x
		writeFloat f tfm.row2.y
		writeFloat f tfm.row2.z
		writeFloat f 0                      --unknown ?? Testing
		writeFloat f tfm.row3.x
		writeFloat f tfm.row3.y
		writeFloat f tfm.row3.z
		writeFloat f 0                      --unknown ?? Testing
		tpos = tfm.row4 * Iscale 
		writeFloat f tpos.x
		writeFloat f tpos.y
		writeFloat f tpos.z    
		writeFloat f 0                      --unknown ?? Testing
	)--end for jj
--New Edit(08Jul05)--**
        if ver == 0x1803FFFF then (
            writeFloat f 0; writeFloat f 0; writeFloat f 0
        )
--**
--New Edit(12Jul05)--**
	if ver != 0x1803FFFF then (
		writeLong f 0x105                       --Morph PLG
		writeLong f 4
		writeLong f ver
		writeLong f 0
		return (skinPlg_size + 28)
	)
--**
	return (skinPlg_size + 12)
	    
)--end fn wSkinPlg				--<e11>--

--New Edit(19Jul05)--**
fn wGeometry f mshAry bonechain MMC TUV CPV NOR Iscale SkinData ver = (		-- 19Jan05 10:35am --
			local msh = mshAry[1]
 --**
			--byte Flag info.
			--      1   use Tri-Strip
			--      2   Position
			--      4   Texture UV
			--      8   Prelit (Vertex Colors)
			--      16  Normal
			--      32  Light
			--      64  Modulate Material Color
			--      128 Textured2 ??
	local GeometryFlags = 32       --Light
 --MMCcheck = getUserProp msh "MMC"
 --format "in wGeometry %:%\n" msh.name MMCcheck
 --if (MMC == true)AND(MMCcheck == true) then (
 --format "MMC Flag set\n"
	if (MMC == true) then (
	GeometryFlags += 64
	)
	if NOR == true then GeometryFlags += 16
	if (msh.numTVerts > 0)AND(TUV == true) then GeometryFlags += 4
	if (msh.numCPVVerts > 0)AND(CPV == true) then GeometryFlags += 8
 --New Edit(19Jul05)--** 
	if (mshAry[2] != undefined)AND(TUV == true) then GeometryFlags += (128 - 4) --Texture2:on, Texture:off
 --**
 --New Edit--***
	if ver == 0X1803FFFF then GeometryFlags += 2
 --***
            
	writeLong f 0x0F				-- rwGeometry
	G_length_add = ftell f
	writeLong f 0			        -- temp for Geometry size
	WriteLong f ver	        		-- file version for GTA3
	writeLong f 1
	msh_length_add = ftell f
	writeLong f 0			        -- temp for mesh size
 	WriteLong f ver	        		-- file version for GTA3
	writeShort f GeometryFlags		-- GeometryFlags
 --New Edit (21Jul05)(08Aug08)--**
	if (mshAry[2] != undefined)AND(TUV == true) then writeShort f 2
	else if (msh.numTVerts > 0)AND(TUV == true) then writeShort f 1
    else writeShort f 0			        -- no. texture in geometry
 --**
	writeLong f msh.numfaces
	writeLong f msh.numverts
	writeLong f 1			        -- no. morph target
 --New Edit--***
	if (ver == 0x1003FFFF)OR(ver == 0x1803FFFF) then ()
	else (
 --	if ver != 0x1003FFFF then (--***
		writeFloat f 1			        -- Ambient
		writeFloat f 1			        -- Diffuse
		writeFloat f 1			        -- Specular
	)
    --Vertex Colors--
    if (msh.numCPVVerts > 0)AND(CPV == true) then (
        for i = 1 to msh.numCPVVerts do (
            VCol = getVertColor msh i
            writeByte f (VCol.r as integer)
            writeByte f (VCol.g as integer)
            writeByte f (VCol.b as integer)
            writeByte f 255
        )--end for i
    )
	--UVs--
	if (msh.numTVerts > 0)AND(TUV == true) then (
		for i = 1 to msh.numTverts do (
			tmp = getTVert msh i
			writeFloat f tmp.x
			writeFloat f ( 1- tmp.y)
		)--end for i
	)	
 --New Edit(19Jul05)--** 
	if (mshAry[2] != undefined)AND(TUV == true) then (
		for i = 1 to mshAry[2].count do (	
			writeFloat f mshAry[2][i].x
			writeFloat f (1 - mshAry[2][i].y)
		)--end for i
	)
 --**
	--faces--
	for i = 1 to msh.numfaces do (
		tmp = getface msh i
		writeShort f (tmp.y - 1)
		writeShort f (tmp.x - 1)
		writeShort f 0
		writeShort f (tmp.z - 1)
	)
	--bounding Sphere--
 --	BSM = for t in msh.children where (classof t == sphere) collect t
 --	if BSM == undefined then (
 --		format "No Bounding Sphere defined in %!\n" msh.name
 --		writeFloat f 0;writeFloat f 0;writeFloat f 0;writeFloat f 0
 --	) else (
 --		writeFloat f (BSM[1].pos.x * Iscale)
 --		writeFloat f (BSM[1].pos.y * Iscale)
 --		writeFloat f (BSM[1].pos.z * Iscale)
 --		writeFloat f (BSM[1].radius * Iscale)
 --	)

    writeFloat f msh.center.x
    writeFloat f msh.center.y
    writeFloat f msh.center.z   

	bkupcenter = msh.center
	msh.center = [0,0,0]
	rds = 0.0
	for v in msh.verts do (
		vt = v.pos * Iscale
		rfp = sqrt((vt.x*vt.x)+(vt.y*vt.y)+(vt.z*vt.z))
		if rds < rfp then rds = rfp
	)
	msh.center = bkupcenter
	writeFloat f rds
	writeLong f 1									--unknown??
	if (NOR == true) then	writeLong f 1			--Normal Flag??
	else	writeLong f 0

	--vertices--
	for i = 1 to msh.numverts do (
		tmp = (getVert msh i) * Iscale
		writeFloat f tmp.x 
		writeFloat f tmp.y
		writeFloat f tmp.z
	)
	--normals--	
	if (NOR == true) then ( 
		for i = 1 to msh.numverts do (
			tmp = getNormal msh i
			writeFloat f tmp.x
			writeFloat f tmp.y
			writeFloat f tmp.z
		)--end for i
	)--end if NOR
	
	local here = ftell f
	msh_length = here - 8 - msh_length_add
	fseek f msh_length_add #seek_set
	writeLong f msh_length
	fseek f here #seek_set
	wMaterialList f msh ver

	writeLong f 0x03				-- rwExtension
	GExt_length_add = ftell f
	writeLong f 0					-- temp for Geometry Extension
 	WriteLong f ver					-- file version for GTA3
    wMaterialSplit f msh ver
	if bonechain != undefined then (
 --format "3: SkinData:%\n" SkinData[1].count
		wSkinPlg f SkinData bonechain Iscale ver
	)

 --New Edit--***
	if ver == 0x1803FFFF then (
		writeLong f 0x0253F2FD
		writeLong f 4
		writeLong f ver
		writeLong f 0
	)
 --***
		
	local here = ftell f
	GExt_length = here - 8 - GExt_length_add
	fseek f GExt_length_add #seek_set
	writeLong f GExt_length
    
	fseek f here #seek_set
    local here = ftell f
	G_length = here - 8 - G_length_add
    
	fseek f G_length_add #seek_set
	writeLong f G_length
	fseek f here #seek_set
)--end fn wGeometry				--<e12>--


--M---------------------
--Main Export Function--
------------------------
fn DFFout f Allobjects MMC TUV CPV NOR ExSc ver SAColBase noCol addlock = (

	Noproblem = true
--	try (
		SkinData = undefined
		bonechain = undefined
		Clump_Start = ftell f
		local ObjAry = for obj in Allobjects where superclassof obj == GeometryClass collect obj 
		wClump f ObjAry.count ver
		wFrameList f Allobjects ExSc ver
		GL_length_add = wGeometryList f Allobjects ver

		for i = 1 to ObjAry.count do (
			tmsh = RemapGeo ObjAry[i] undefined
			if tmsh != undefined then (
				tmsh[1] = CondenseMtlByID tmsh[1]
				tmsh[1].transform = (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
				wGeometry f tmsh undefined MMC TUV CPV NOR ExSc undefined ver 
				delete tmsh[1]
			) else (
				Noproblem = false
				format "Can't export: %\n>>>This dff WON'T work<<<\n" ObjAry[i]
			)--end if tmsh
		)--end for i

		local here = ftell f
		GL_length = here - 8 - GL_length_add
		fseek f GL_length_add #seek_set
		writeLong f GL_length
		fseek f here #seek_set
		
		noGeo = 0
		for i = 1 to Allobjects.count do (
			if superclassof Allobjects[i] == GeometryClass then (
				wAtomic f i (i - noGeo) ver noCol
			) else noGeo += 1
		)
--New Edit(18Jul05)--***
		for i = 1 to Allobjects.count do (
			if superclassof Allobjects[i] == light then (
				--rwLight--
				writeLong f 0x01
				writeLong f 4
				writeLong f ver
				writeLong f (i-1)
				writeLong f 0x12
				writeLong f 48
				writeLong f ver
				writeLong f 0x01
				writeLong f 24
				writeLong f ver
                
				writeFloat f (Allobjects[i].farAttenEnd)
				writeFloat f (Allobjects[i].color.r / 255)
				writeFloat f (Allobjects[i].color.g / 255)
				writeFloat f (Allobjects[i].color.b / 255)
				writeFloat f 0
				writeShort f 3
				if classof Allobjects[i] == Omnilight then writeShort f 0x80
                else writeShort f 0x81

				writeLong f 0x03
				writeLong f 0
				writeLong f ver
			)
		)
--**
		WriteLong f 3
--New Edit--***
		EndExtAdd = ftell f
--***
		WriteLong f 0
		WriteLong f ver	-- file version for GTA3
        
--New Edit(09Jul05)--***
		if (ver == 0X1803FFFF)AND(noCol == 0) then (
            if findstring SAColBase ".dff" != undefined then    ret = writeCOL3 SAColBase f ver 
            else ret = writeCOLL SAColBase f ver 

			endhere = ftell f
			if ret == true then (
				EndExtLeng = endhere - EndExtAdd - 8
				fseek f EndExtAdd #seek_set
				writelong f EndExtLeng
				fseek f endhere #seek_set
			) else (
				ermsg = "Error in reading " + SAColBase + " Collision Data!!\nThis file will not work ingame!!"
				messagebox ermsg
			)
		) --else endhere = ftell f
--***
		endhere = ftell f

--**New Edit (19Aug05)--
--Add zmod lock here--
	if addlock == true then (
		h1 = random 0 255
		h2 = random 0 252
		e1 = h1 - 31 						--original should - 32
		e2 = h2 + 1 						--original should + 3
		WriteLong f 0xF21E
		WriteLong f 8
		WriteLong f ver
		WriteByte f h1
		WriteByte f h2
		WriteShort f 0x1C15
		WriteShort f 0x9493		--original should be 0x61031C15
		WriteByte f e1
		WriteByte f e2
	)
--**
        
		clump_length = endhere - 12 - Clump_Start
		fseek f (Clump_Start+4) #seek_set
		writeLong f clump_length		

		--fclose f
        return Noproblem
--	) catch ( return false )

)--end fn DFFout				--<M1>--


fn wCharDFFout f obj bonechain MMC TUV CPV NOR ExSc SkinData ver addlock = (
	Noproblem = true
    
	Clump_Start = ftell f
	wClump f 1 ver
	wSkinFrameList f bonechain ExSc ver
	GL_length_add = wGeometryList f obj ver
	tmsh = RemapGeo obj	SkinData
    if tmsh != undefined then tmsh[1] = CondenseMtlByID tmsh[1]
--format "tmsh[3]:%\n" tmsh[3][1].count
	tmsh[1].transform = (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
    SkinData = tmsh[3]
--format"2: SkinData:%\n" SkinData[1].count
	wGeometry f tmsh bonechain MMC TUV CPV NOR ExSc SkinData ver
	delete tmsh[1]
	local here = ftell f
	GL_length = here - 8 - GL_length_add
	fseek f GL_length_add #seek_set
	writeLong f GL_length
	fseek f here #seek_set
	wSkinAtomic f 1 1 ver
	
	WriteLong f 3
	WriteLong f 0
	WriteLong f ver	-- file version for GTA3
	endhere = ftell f
    
--**New Edit (19Aug05)(15Sep05)--
--Add zmod lock here--
	if addlock == true then (
		h1 = random 0 255
		h2 = random 0 252
		e1 = h1 - 31 						--original should - 32
		e2 = h2 + 1 						--original should + 3
		WriteLong f 0xF21E
		WriteLong f 8
		WriteLong f ver
		WriteByte f h1
		WriteByte f h2
		WriteShort f 0x1C15
		WriteShort f 0x9493		--original should be 0x61031C15
		WriteByte f e1
		WriteByte f e2
	)
--**
	clump_length = endhere - 12 - Clump_Start
	fseek f (Clump_Start+4) #seek_set
	writeLong f clump_length
	
	return Noproblem
	
)--end fn wCharDFFout			--<M2>--


fn DFFoutInfo = (
	format "\nDFFout SA Beta\n"
	format " - Collision Quick Hack\n - Same GeometryFlag for all objects only\n"
    format " - Material Matching based on ashdexx's explanation, many thanks!\n" 
    format " - export GTA Material\n"
    format " - bones/skins try (18Jul05)\n"
    format " - rwLight try\n"
    format " - 2nd UV Map\n"
    format " - Vehicle Parts try\n"
    format " - Lock added\n"
	format "\nby Kam\t\t19Dec05\nkam.lai@ntlworld.com\n\n"
    
    return (051219)
)