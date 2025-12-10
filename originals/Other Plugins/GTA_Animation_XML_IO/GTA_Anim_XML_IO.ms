----------------------------------------------------------------
--
--  File:			GTA_Anim_XML_IO.ms
--  Description:	Load and Save whole animations and mappings into XML user-readable format.
--  By:				Wesser - Wesser@hotmail.com
--
--  History:
--
--		19/09/11	Fixed previous feature so that it works also when "Export keys for each time" isn't checked. (1.15)
--
--		04/09/10	Added support for exporting planted and sliding biped keys. (1.1)
--
--		09/08/10	First beta release. (1.0)
--
----------------------------------------------------------------
global globalVer = "1.15" --global maxscript version
----------------------------------------------------------------
global animVer   = "1.00" --saved animation version
global mapVer    = "1.00" --saved mapping version
----------------------------------------------------------------

global XMLAnim, XMLAbout, XMLSource, XMLMap --rollout definition

global gXmlAnIO, gXmlAmIO                   --xml structs definition

function openAnimDialog =
(
	global GTA_Anim = newRolloutFloater ("GTA Animation XML IO " + globalVer) 175 300 10 30
	addRollout XMLAnim GTA_Anim
	addRollout XMLAbout GTA_Anim
)

function openMapDialog =
(
	global GTA_Anim_Map = newRolloutFloater "GTA Animation Mapping" 610 635 0 0
	addRollout XMLSource GTA_Anim_Map
	addRollout XMLMap GTA_Anim_Map
)

struct xmlAnimIO
(
	xmlDoc,
	m_xmlDoc,
	function init =
	(
		dotnet.LoadAssembly "system.xml.dll"

		xmlDoc = dotNetObject "System.Xml.XmlDocument"

		m_xmlDoc = xmlDoc.createElement "GTAnimation"
		m_xmlDoc.setAttribute "version" animVer
		m_xmlDoc.setAttribute "date" localTime
		xmlDoc.appendChild m_xmlDoc

		local infoElem = xmlDoc.createElement "AnimInfo"
		infoElem.setAttribute "startTime" "0"
		infoElem.setAttribute "endTime" "0"
		m_xmlDoc.appendChild infoElem
	),
	function load xmlDocName =
	(
		xmlDoc.load(xmlDocName)

		m_xmlDoc = (xmlDoc.getElementsByTagName "GTAnimation").item[0]
	),
	function save xmlDocName =
	(
		xmlDoc.save(xmlDocName)
	),
	function clear =
	(
		xmlDoc = undefined
		m_xmlDoc = undefined
	),
	function setAnimInfo startTime endTime =
	(
		local infoElem = (m_xmlDoc.getElementsByTagName "AnimInfo").item[0]
		infoElem.setAttribute "startTime" (startTime as string)
		infoElem.setAttribute "endTime" (endTime as string)
	),
	function createAnimNode nodeName =
	(
		local nodeElem = xmlDoc.createElement "Node"
		nodeElem.setAttribute "name" nodeName
		m_xmlDoc.appendChild nodeElem

		local posElem = xmlDoc.createElement "Position"
		nodeElem.appendChild posElem
		local rotElem = xmlDoc.createElement "Rotation"
		nodeElem.appendChild rotElem

		return nodeElem
	),
	function setAnimPosition nodeElem keyframe posX posY posZ =
	(
		local frameElem = xmlDoc.createElement "s"
		frameElem.setAttribute "t" (keyframe as string)
		frameElem.setAttribute "v" ((posX as string) + ", " + (posY as string) + ", " + (posZ as string))
		local posElem = nodeElem.getElementsByTagName "Position"
		posElem.item[0].appendChild frameElem
	),
	function setAnimRotation nodeElem keyframe rotX rotY rotZ =
	(
		local frameElem = xmlDoc.createElement "s"
		frameElem.setAttribute "t" (keyframe as string)
		frameElem.setAttribute "v" ((rotX as string) + ", " + (rotY as string) + ", " + (rotZ as string))
		local rotElem = (nodeElem.getElementsByTagName "Rotation").item[0]
		rotElem.appendChild frameElem
	),
	function getStartTime =
	(
		return (m_xmlDoc.getElementsByTagName "AnimInfo").item[0].getAttribute "startTime"
	),
	function getEndTime =
	(
		return (m_xmlDoc.getElementsByTagName "AnimInfo").item[0].getAttribute "endTime"
	),
	function getKeyFrames =
	(
		return abs((getEndTime() as integer) - (getStartTime() as integer)) + 1
	),
	function getNodeCount =
	(
		return (m_xmlDoc.getElementsByTagName "Node").count
	),
	function getNodeById nodeIndex =
	(
		return (m_xmlDoc.getElementsByTagName "Node").item[nodeIndex]
	),
	function getNodeName nodeIndex =
	(
		return (getNodeById nodeIndex).getAttribute "name"
	),
	function getNodeIndexByName nodeName =
	(
		for i = 0 to getNodeCount() - 1 do
		(
			if (getNodeName i) == nodeName then return i
		)

		return undefined
	),
	function getNodePosKeys nodeIndex  =
	(
		return (((getNodeById nodeIndex).getElementsByTagName "Position").item[0].getElementsByTagName "s").count
	),
	function getNodePosKeyById nodeIndex keyIndex =
	(
		return (((getNodeById nodeIndex).getElementsByTagName "Position").item[0].getElementsByTagName "s").item[keyIndex]
	),
	function getNodePosKeyFrame nodeIndex keyIndex =
	(
		return ((getNodePosKeyById nodeIndex keyIndex).getAttribute "t") as time
	),
	function getNodePosKeyXYZ nodeIndex keyIndex =
	(
		return filterString ((getNodePosKeyById nodeIndex keyIndex).getAttribute "v") ", "
	),
	function getNodeRotKeys nodeIndex  =
	(
		return (((getNodeById nodeIndex).getElementsByTagName "Rotation").item[0].getElementsByTagName "s").count
	),
	function getNodeRotKeyById nodeIndex keyIndex =
	(
		return (((getNodeById nodeIndex).getElementsByTagName "Rotation").item[0].getElementsByTagName "s").item[keyIndex]
	),
	function getNodeRotKeyFrame nodeIndex keyIndex =
	(
		return ((getNodeRotKeyById nodeIndex keyIndex).getAttribute "t") as time
	),
	function getNodeRotKeyXYZ nodeIndex keyIndex =
	(
		return filterString ((getNodeRotKeyById nodeIndex keyIndex).getAttribute "v") ", "
	),
	function print = 
	(
		format "Total Frames: %\n" (getKeyFrames())
		format "Start Time: %\n" (getStartTime())
		format "End Time: %\n\n" (getEndTime())

		for i = 1 to getNodeCount() do
		(
			format "Node: %\tPosKeys: %\tRotKeys: %\n" (getNodeName (i - 1)) (getNodePosKeys (i - 1)) (getNodeRotKeys (i - 1))
		)
	),
	_init = init() --initialize init fn automatically
)

struct xmlMapIO
(
	xmlDoc,
	m_xmlDoc,
	function init =
	(
		dotnet.LoadAssembly "system.xml.dll"

		xmlDoc = dotNetObject "System.Xml.XmlDocument"

		m_xmlDoc = xmlDoc.createElement "GTAMapping"
		m_xmlDoc.setAttribute "version" mapVer
		m_xmlDoc.setAttribute "date" localTime
		xmlDoc.appendChild m_xmlDoc
	),
	function load xmlDocName =
	(
		xmlDoc.load(xmlDocName)

		m_xmlDoc = (xmlDoc.getElementsByTagName "GTAMapping").item[0]
	),
	function save xmlDocName =
	(
		xmlDoc.save(xmlDocName)
	),
	function clear =
	(
		xmlDoc = undefined
		m_xmlDoc = undefined
	),
	function setNodeMapping nodeName mapName =
	(
		local mapElem = xmlDoc.createElement "Map"
		mapElem.setAttribute "name" nodeName
		mapElem.setAttribute "mapName" mapName
		m_xmlDoc.appendChild mapElem
	),
	function getMapCount =
	(
		return (m_xmlDoc.getElementsByTagName "Map").count
	),
	function getMapById mapIndex =
	(
		return (m_xmlDoc.getElementsByTagName "Map").item[mapIndex]
	),
	function getNodeName mapIndex =
	(
		return (getMapById mapIndex).getAttribute "name"
	),
	function getMapName mapIndex =
	(
		return (getMapById mapIndex).getAttribute "mapName"
	),
	function print = 
	(
		format "Total Map Nodes: %\n\n" (getMapCount())

		for i = 1 to getMapCount() do
		(
			format "Node: %\tMapName: %\n" (getNodeName (i - 1)) (getMapName (i - 1))
		)
	),
	_init = init() --initialize init fn automatically
)

rollout XMLAnim "Importer/Exporter"
(
	group "Timeline"
	(
		spinner spAnimStart "Start" fieldwidth:30 range:[-1000000,100000,animationRange.start] type:#integer align:#center across:2
		spinner spAnimEnd "End" fieldwidth:30 range:[-100000,100000,animationRange.end] type:#integer align:#center
		checkbox chkKeyFrames "Export keys for each time" height:15 checked:true
	)

	button btnSaveAnim "Save Animation" width:120 align:#center tooltip:"Only selected objects will be affected!"
	button btnLoadAnim "Load Animation" offset:[0,-3] width:120 align:#center tooltip:"Only selected objects will be affected!"

	function numKeysBip bipCtrl =
	(
		return bipCtrl.keys.count
	)

	function isKeySetBip bipCtrl keytime =
	(
		return getKeyIndex bipCtrl keytime > 0
	)
/*
	function getKeyTimeBip bipCtrl keytime =
	(
		return bipCtrl.keys[keytime].time
	)
*/
	function getFirstKeyTimeBip bipCtrl =
	(
		return (biped.getCurrentRange bipCtrl).start
	)

	function getLastKeyTimeBip bipCtrl =
	(
		return (biped.getCurrentRange bipCtrl).end
	)

	function isNodeAnchorBip bipRef =
	(
		return biped.getIKActive bipRef.controller ((biped.getIdLink bipRef).x - 1)
	)

	function bipToObj bipRef chkKeys =
	(
		local obj = snapshot bipRef name:bipRef.name wirecolor:bipRef.wirecolor

		with animate on
		(
			if bipRef.controller.rootNode != bipRef then
			(
				local bipKeys = numKeysBip bipRef.controller

				local zeroKey = if bipKeys > 0 then XMLMap.isZeroKey bipRef.controller bipKeys (getFirstKeyTimeBip bipRef.controller) else false

				if bipKeys > 0 then
				(
					local startBipCtrl = (biped.getCurrentRange bipRef.controller).start
					local endBipCtrl = (biped.getCurrentRange bipRef.controller).end

					for i = startBipCtrl to endBipCtrl do
					(
						at time i if chkKeys or isKeySetBip bipRef.controller i or isNodeAnchorBip bipRef then obj.transform = bipRef.transform
					)

					deleteKeys obj.scale.controller #allKeys
				)

				if zeroKey then (deleteKey obj.position.controller 1; deleteKey obj.rotation.controller 1)
			)
			else
			(
				local bipVKeys = numKeys bipRef.transform.controller.vertical.controller
				local bipHKeys = numKeys bipRef.transform.controller.horizontal.controller
				local bipTKeys = numKeys bipRef.transform.controller.turning.controller

				local bipKeys = amax #(bipVKeys, bipHKeys, bipTKeys)

				local zeroVKey = if bipVKeys > 0 then XMLMap.isZeroKey bipRef.transform.controller.vertical.controller bipVKeys (getFirstKeyTimeBip bipRef.transform.controller.vertical.controller) else false
				local zeroHKey = if bipHKeys > 0 then XMLMap.isZeroKey bipRef.transform.controller.horizontal.controller bipHKeys (getFirstKeyTimeBip bipRef.transform.controller.horizontal.controller) else false
				local zeroTKey = if bipTKeys > 0 then XMLMap.isZeroKey bipRef.transform.controller.turning.controller bipTKeys (getFirstKeyTimeBip bipRef.transform.controller.turning.controller) else false

				if bipKeys > 0 then
				(
					local startBipCtrl = if chkKeys then (if bipVKeys > 0 then getFirstKeyTimeBip bipRef.transform.controller else 0f) else 1
					local endBipCtrl = if chkKeys then (if bipVKeys > 0 then getLastKeyTimeBip bipRef.transform.controller else 0f) else bipKeys

					for i = startBipCtrl to endBipCtrl do
					(
						local chkVKeys = if not chkKeys then (if bipVKeys >= i then true else false) else true

						if chkVKeys then
						(
							local key = if not chkKeys then (biped.getkey bipRef.transform.controller.vertical.controller i).time else i

							at time key obj.position.controller.z_position = bipRef.transform.position.z
						)

						local chkHKeys = if not chkKeys then (if bipHKeys >= i then true else false) else true

						if chkHKeys then
						(
							local key = if not chkKeys then (biped.getkey bipRef.transform.controller.horizontal.controller i).time else i

							at time key obj.position.controller.x_position = bipRef.transform.position.x
							at time key obj.position.controller.y_position = bipRef.transform.position.y
						)

						local chkTKeys = if not chkKeys then (if bipTKeys >= i then true else false) else true

						if chkTKeys then
						(
							local key = if not chkKeys then (biped.getkey bipRef.transform.controller.turning.controller i).time else i

							at time key obj.rotation.controller.x_rotation = (bipRef.transform.rotation as eulerangles).x
							at time key obj.rotation.controller.y_rotation = (bipRef.transform.rotation as eulerangles).y
							at time key obj.rotation.controller.z_rotation = (bipRef.transform.rotation as eulerangles).z
						)
					)
				)

				if zeroVKey or zeroHKey then deleteKey obj.position.controller 1
				if zeroTKey then deleteKey obj.rotation.controller 1
			)
		)

		return obj
	)

	on btnSaveAnim pressed do
	(
		if $selection.count > 0 then
		(
			fpath = getSaveFileName caption:"Export XAN File" types:"GTA XML Animation File (*.xan)|*.xan|"

			if fpath != undefined then
			(
				if (getFileNameType fpath) == ".xan" then
				(
					disablesceneredraw()

					gXmlAnIO = xmlAnimIO()

					local obj = undefined
					local ar_keys = #()

					for obj in $selection do
					(
						local objRef = if classof obj == Biped_Object then obj
						local obj = if classof obj == Biped_Object then bipToObj obj chkKeyFrames.checked else obj

						local posKeys = numKeys obj.position.controller
						local rotKeys = numKeys obj.rotation.controller

						local nodeElem = gXmlAnIO.createAnimNode obj.name

						if posKeys > 0 then
						(
							local startPosCtrl = if chkKeyFrames.checked then (getKeyTime obj.position.controller 1) else 1
							local endPosCtrl = if chkKeyFrames.checked then (getKeyTime obj.position.controller posKeys) else posKeys

							for i = startPosCtrl to endPosCtrl do
							(
								local key = if not chkKeyFrames.checked then getKeyTime obj.position.controller i else i

								if key >= spAnimStart.value and key <= spAnimEnd.value then
								(
									at time key local x = obj.position.controller.x_position
									at time key local y = obj.position.controller.y_position
									at time key local z = obj.position.controller.z_position

									gXmlAnIO.setAnimPosition nodeElem key x y z

									append ar_keys key
								)
							)
						)

						if rotKeys > 0 then
						(
							local startRotCtrl = if chkKeyFrames.checked then (getKeyTime obj.rotation.controller 1) else 1
							local endRotCtrl = if chkKeyFrames.checked then (getKeyTime obj.rotation.controller rotKeys) else rotKeys

							for i = startRotCtrl to endRotCtrl do
							(
								local key = if not chkKeyFrames.checked then getKeyTime obj.rotation.controller i else i

								if key >= spAnimStart.value and key <= spAnimEnd.value then
								(
									at time key local x = obj.rotation.controller.x_rotation
									at time key local y = obj.rotation.controller.y_rotation
									at time key local z = obj.rotation.controller.z_rotation

									gXmlAnIO.setAnimRotation nodeElem key x y z

									append ar_keys key
								)
							)
						)

						if classof objRef == Biped_Object then delete obj
					)

					if ar_keys.count > 0 then gXmlAnIO.setAnimInfo (amin ar_keys) (amax ar_keys) --else gXmlAnIO.setAnimInfo 0 0

					gXmlAnIO.save fpath

					clearlistener()
					gXmlAnIO.print()

					gXmlAnIO.clear()

					enablesceneredraw()
					redrawviews()
				)
				else
				(
					messagebox "Wrong file extension! It must be 'xan'!" title:"Error"
				)
			)
		)
		else
		(
			messagebox "Select at least an object!" title:"Error"
		)
	)--end on btnSaveAnim
	
	on btnLoadAnim pressed do
	(
		if $*.count > 0 then
		(
			closeRolloutFloater GTA_Anim
			openMapDialog()
		)
		else
		(
			messageBox "No object in scene to animate!" title:"Error"
		)
	)--end on btnLoadAnim
)--end rollout XMLAnim

rollout XMLAbout "About"
(
	label abtlbl1 "Powered by Wesser";
	label abtlbl2 "http://wesser.altervista.org/";
	label abtlbl3 "Wesser@hotmail.it";
	label abtlbl4 "";
	label abtlbl5 "Wesser © Copyright 2010";
	label abtlbl6 "All Rights Reserved";
)--end rollout XMLAnim

----------------------------------------------------------------
--  GTA ANIMATION MAPPING
----------------------------------------------------------------

global animPath = undefined

global src_width = 230, cur_width = 330, lv_height = 315, txt_width = 250, btn_width = 100, btn_height = 25, lv_pad = 30

function stringPathSplit path width =
(
	local fpath = pathConfig.removePathLeaf path
	local fname = pathConfig.stripPathToLeaf path

	if (GetTextExtent path).x > width then
	(
		local temp_path = ""
		local count = 0

		while width - 15 > (GetTextExtent temp_path).x do
		(
			temp_path = (substring path 1 count) + "...\\" + fname

			count += 1
		)

		return temp_path
	)
	else
	(
		return fpath + "\\" + fname
	)
)

rollout XMLSource "Source"
(
	local attr_width = 90, attr_height = 100, time_width = 195, time_height = 97, x_offset = 5, y_offset = 5

	local opt_width = attr_width + time_width + 15, opt_height = if attr_height > time_height then attr_height + 20 else time_height + 20

	----------------------------------------------------------------------------
	groupBox grpBoxOpt "Options" pos:[x_offset,y_offset] width:opt_width height:opt_height
	----------------------------------------------------------------------------
	groupBox grpBoxAttr "Attributes" pos:[x_offset+5,y_offset+15] width:attr_width height:attr_height across:2
	----------------------------------------------------------------------------
	checkbox chkTransform "Transform" pos:[x_offset+10,y_offset+35] height:15 checked:true
	checkbox chkPosition "Position" pos:[x_offset+20,y_offset+55] width:60 height:15 checked:true
	checkbox chkChildren "Children" pos:[x_offset+30,y_offset+75] width:60 height:15
	checkbox chkRotation "Rotation" pos:[x_offset+20,y_offset+95] width:60 height:15 checked:true
	----------------------------------------------------------------------------
	groupBox grpBoxTime "Time Range" pos:[x_offset+attr_width+10,y_offset+15] width:time_width height:time_height
	----------------------------------------------------------------------------
	radiobuttons rbCtrl labels:#("Replace Animation", "Paste to Existing Animation") pos:[x_offset+attr_width+15,y_offset+35] columns:1 default:1
	checkbox chkTimeRange "Insert Animation with:" pos:[x_offset+attr_width+15,y_offset+70] height:15
	spinner spStartTime "StartTime:" pos:[x_offset+attr_width+20,y_offset+90] fieldwidth:30 range:[-100000,100000,currentTime] type:#integer enabled:false
	spinner spFrames "Frames:" pos:[x_offset+attr_width+115,y_offset+90] fieldwidth:30 range:[0,0,0] type:#integer enabled:false
	----------------------------------------------------------------------------
	editText txtAnimPath "" pos:[(x_offset+opt_width)+((src_width+cur_width+lv_pad)-(x_offset+opt_width))/2-(txt_width/2),y_offset+opt_height/2-12] width:txt_width height:20 readOnly:true
	button btnGetAnim "Get Animation" pos:[(x_offset+opt_width)+((src_width+cur_width+lv_pad)-(x_offset+opt_width))/2-(btn_width/2),y_offset+opt_height/2+12] width:btn_width height:20 tooltip:"Get existing animation where saved"
	----------------------------------------------------------------------------

	function setAnimRange startTime keyframes =
	(
		spStartTime.value = (startTime as integer)
		spFrames.range = [0,keyframes,keyframes]
	)

	on chkTransform changed state do
	(
		chkPosition.enabled = chkRotation.enabled = state

		if chkPosition.checked then chkChildren.enabled = state
	)--end on chkTransform

	on chkPosition changed state do chkChildren.enabled = state

	on chkTimeRange changed state do spStartTime.enabled = spFrames.enabled = state

	on btnGetAnim pressed do
	(
		local fpath = getOpenFileName caption:"Import XAN File" types:"GTA XML Animation File (*.xan)|*.xan|"

		if fpath != undefined then
		(
			if (getFileNameType fpath) == ".xan" then
			(
				txtAnimPath.text = stringPathSplit fpath txt_width
				animPath = fpath

				gXmlAnIO = xmlAnimIO()

				gXmlAnIO.load fpath

				setAnimRange (gXmlAnIO.getStartTime()) (gXmlAnIO.getKeyFrames())

				XMLMap.addXMLNodesToListView gXmlAnIO XMLMap.lvSource

				clearlistener()
				gXmlAnIO.print()

				--gXmlAnIO.clear()
			)
			else
			(
				messagebox "Wrong file extension! It must be 'xan'!" title:"Error"
			)
		)
	)--end on btnGetAnim
)--end rollout XMLSource

rollout XMLMap "Mapping"
(
	local half_width = (src_width + cur_width + lv_pad + 20) / 2

	----------------------------------------------------------------------------
	label lblSource "SOURCE OBJECTS:" pos:[5,10]
	label lblCurrent "CURRENT OBJECTS:" pos:[src_width+lv_pad,10]
	----------------------------------------------------------------------------
	dotNetControl lvSource "System.Windows.Forms.ListView" pos:[5,30] width:src_width height:lv_height
	dotNetControl lvCurrent "System.Windows.Forms.ListView" pos:[src_width+lv_pad,30] width:cur_width height:lv_height
	----------------------------------------------------------------------------
	button btnRight "»" pos:[src_width+5,lv_height/2-(btn_height*4+15)/2+30] width:(lv_pad-5) height:btn_height tooltip:"Add"
	button btnLeft "«" pos:[src_width+5,lv_height/2-(btn_height*4+15)/2+(btn_height+5)+30] width:(lv_pad-5) height:btn_height tooltip:"Delete"
	button btnRefresh "R" pos:[src_width+5,lv_height/2-(btn_height*4+15)/2+(btn_height+5)*2+30] width:(lv_pad-5) height:btn_height tooltip:"Refresh"
	button btnAutoMap "A" pos:[src_width+5,lv_height/2-(btn_height*4+15)/2+(btn_height+5)*3+30] width:(lv_pad-5) height:btn_height tooltip:"Auto Mapping"
	----------------------------------------------------------------------------
	groupBox grpBoxMap "Import/Export" width:(src_width+cur_width+lv_pad-4) height:47 pos:[5,lv_height+35]
	----------------------------------------------------------------------------
	editText txtMapPath "" pos:[half_width-(txt_width+(btn_width*2)+lv_pad)/2,lv_height+55] width:txt_width height:20 across:3 readOnly:true
	button btnLoadMap "Load Mapping" pos:[half_width-(txt_width+(btn_width*2)+lv_pad)/2+txt_width+(lv_pad/4),lv_height+55] width:btn_width height:20 tooltip:"Load mapping which has been already saved"
 	button btnSaveMap "Save Mapping" pos:[half_width-(txt_width+(btn_width*2)+lv_pad)/2+txt_width+btn_width+(lv_pad/2),lv_height+55] width:btn_width height:20 tooltip:"Save mapping with actual properties"
	----------------------------------------------------------------------------
	button btnLoadMotion "Load Motion" pos:[half_width-155,lv_height+87] width:300 height:40 tooltip:"Load animation currently mapped"
	----------------------------------------------------------------------------

	function initListView lv =
	(
		lv.view = (dotNetClass "System.Windows.Forms.View").details
		lv.fullRowSelect = true
		lv.gridLines = true
		lv.hideSelection = false
		lv.backColor = (dotNetClass "System.Drawing.Color").fromArgb 230 230 230
		lv.multiSelect = false

		local imgList = dotNetObject "System.Windows.Forms.ImageList"
		imgList.imageSize = dotNetObject "System.Drawing.Size" 10 10
		lvCurrent.smallImageList = imgList
	)

	function addListViewCols lv cols width =
	(
		for i in cols do
		(
			lv.columns.add i width
		)
	)

	function indentObjHier obj =
	(
		local indentObj = 0

		if obj.parent != undefined then
		(
			local parentObj = obj.parent

			while parentObj != undefined do
			(
				indentObj += 1
				parentObj = parentObj.parent
			)
		)

		return indentObj
	)

	function addSceneObjToListView lv =
	(
 		for obj in $* do
		(
			local li = dotNetObject "System.Windows.Forms.ListViewItem" obj.name
			li.indentCount = indentObjHier obj
			lv.items.add li
		)
	)

	function addXMLNodesToListView xmlDoc lv =
	(
		local nodeCount = xmlDoc.getNodeCount()

		for i = 1 to nodeCount do
		(
			local li = dotNetObject "System.Windows.Forms.ListViewItem" (xmlDoc.getNodeName (i - 1))
			lv.items.add li
		)
	)

	function findItems lv strvalue =
	(
		/* ListView.Items.Find doesn't work for me */

		local ar_items = #()

		for i = 0 to lv.items.count - 1 do
		(
			if lv.items.item[i].text == strvalue then
			(
				append ar_items lv.items.item[i]
			)
		)

		return ar_items
	)

	function isListViewEmpty lv =
	(
		return lv.items.count == 0
	)

	function isListViewMapped lv =
	(
		for i = 0 to lv.items.count - 1 do
		(
			if lv.items.item[i].subItems.count > 1 then return true
		)

		return false
	)

	function isZeroKey objCtrl posKeys firstKey = 
	(
		if posKeys > 0 then
		(
			if (numKeys objCtrl) > 0 then
			(
				if (getKeyTime objCtrl 1) > 0f and firstKey > 0f then
				(
					return true
				)
			)
			else if firstKey > 0f then
			(
				return true
			)

			return false
		)
	)

	on XMLMap open do
	(
		initListView lvSource
		addListViewCols lvSource #("Source Nodes") (src_width-4)
		initListView lvCurrent
		addListViewCols lvCurrent #("Current Nodes", "Merge Nodes") (cur_width/2-2)
		addSceneObjToListView lvCurrent
	)--end on XMLMap open

	on XMLMap close do
	(
		if gXmlAnIO != undefined then gXmlAnIO.clear()

		animPath = undefined
		openAnimDialog()
	)--end on XMLMap close

	on btnRight pressed do
	(
		if lvSource.selectedIndices.count > 0 and lvCurrent.selectedIndices.count > 0 then
		(
			local lvCurItem = lvCurrent.items.item[lvCurrent.selectedIndices.item[0]]
			local lvSrcItem = lvSource.items.item[lvSource.selectedIndices.item[0]]

			if lvCurItem.subItems.count == 1 then
			(
				lvCurItem.subItems.add lvSrcItem.text
			)
		)
	)--end on btnRight

	on btnLeft pressed do
	(
		if lvCurrent.selectedIndices.count > 0 then
		(
			local lvCurItem = lvCurrent.items.item[lvCurrent.selectedIndices.item[0]]

			if lvCurItem.subItems.count > 1 then
			(
				lvCurItem.subItems.removeAt 1
			)
		)
	)--end on btnLeft

	on btnRefresh pressed do
	(
		lvCurrent.items.clear()
		addSceneObjToListView lvCurrent
	)--end on btnRefresh

	on btnAutoMap pressed do
	(
		lvCurrent.items.clear()
		addSceneObjToListView lvCurrent

		local lvSrcItems = lvSource.items

		for i = 0 to lvSrcItems.count - 1 do
		(
			local lvCurItems = findItems lvCurrent lvSrcItems.item[i].text

			if lvCurItems.count > 0 then
			(
				for j = 1 to lvCurItems.count do
				(
					lvCurItems[j].subItems.add lvSrcItems.item[i].text
				)
			)
		)
	)--end on btnAutoMap

	on btnLoadMap pressed do
	(
		if not isListViewEmpty lvSource then
		(
			local fpath = getOpenFileName caption:"Import XAM File" filename:(if animPath != undefined then ((substring animPath 1 (animPath.count - 4)) + ".xam") else "") types:"GTA XML Animation Map File (*.xam)|*.xam|"

			if fpath != undefined then
			(
				if (getFileNameType fpath) == ".xam" then
				(
					txtMapPath.text = stringPathSplit fpath txt_width

					lvCurrent.items.clear()
					addSceneObjToListView lvCurrent

					gXmlAmIO = xmlMapIO()

					gXmlAmIO.load fpath

					for i = 0 to gXmlAmIO.getMapCount() - 1 do
					(
						local lvCurItems = findItems lvCurrent (gXmlAmIO.getNodeName i)

						if lvCurItems.count > 0 then
						(
							local lvSrcItems = findItems lvSource (gXmlAmIO.getMapName i)

							if lvSrcItems.count > 0 then
							(
								lvCurItems[1].subItems.add (gXmlAmIO.getMapName i)
							)
						)
					)

					clearlistener()
					gXmlAmIO.print()

					gXmlAmIO.clear()
				)
				else
				(
					messagebox "Wrong file extension! It must be 'xam'!" title:"Error"
				)
			)
		)
		else
		(
			messagebox "No animation file loaded!" title:"Error"
		)
	)--end on btnLoadMap

	on btnSaveMap pressed do
	(
		if isListViewMapped lvCurrent then
		(
			local fpath = getSaveFileName caption:"Export XAM File" filename:(if animPath != undefined then ((substring animPath 1 (animPath.count - 4)) + ".xam") else "") types:"GTA XML Animation Map File (*.xam)|*.xam|"

			if fpath != undefined then
			(
				if (getFileNameType fpath) == ".xam" then
				(
					gXmlAmIO = xmlMapIO()

					for i = 0 to lvCurrent.items.count - 1 do
					(
						if lvCurrent.items.item[i].subItems.count > 1 then gXmlAmIO.setNodeMapping lvCurrent.items.item[i].text lvCurrent.items.item[i].subItems.item[1].text
					)

					gXmlAmIO.save fpath

					clearlistener()
					gXmlAmIO.print()

					gXmlAmIO.clear()
				)
				else
				(
					messagebox "Wrong file extension! It must be 'xam'!" title:"Error"
				)
			)
		)
		else
		(
			messageBox "No object has been matched yet!" title:"Error"
		)
	)--end on btnSaveMap

	on btnLoadMotion pressed do
	(
		if XMLSource.txtAnimPath.text != "" then
		(
			if isListViewMapped lvCurrent then
			(
				--gXmlAnIO = xmlAnimIO()

				--gXmlAnIO.load fpath

				disablesceneredraw()

				if XMLSource.rbCtrl.state == 1 then
				(
					for i = 0 to lvCurrent.items.count - 1 do
					(
						if lvCurrent.items.item[i].subItems.count > 1 then
						(
							local obj = getNodeByName lvCurrent.items.item[i].text

							if XMLSource.rbCtrl.state == 1 then
							(
								if classof obj == Biped_Object then
								(
									if obj.controller.rootNode != obj then
									(
										biped.deleteKeys obj.controller #allKeys
									)
									else
									(
										biped.deleteKeys obj.transform.controller.vertical.controller #allKeys
										biped.deleteKeys obj.transform.controller.horizontal.controller #allKeys
										biped.deleteKeys obj.transform.controller.turning.controller #allKeys
									)
								)
								else
								(
									deleteKeys obj #allKeys
								)
							)
						)
					)
				)

				local ar_keys = #()

				for i = 0 to lvCurrent.items.count - 1 do
				(
					if lvCurrent.items.item[i].subItems.count > 1 then
					(
						local obj = getNodeByName lvCurrent.items.item[i].text

						local objRef = if classof obj == Biped_Object then obj
						local obj = if classof obj == Biped_Object then XMLAnim.bipToObj obj false else obj

						local idx = gXmlAnIO.getNodeIndexByName lvCurrent.items.item[i].subItems.item[1].text

						with animate on
						(
							if XMLSource.chkPosition.checked then
							(
								if XMLSource.chkChildren.checked or obj.parent == undefined then
								(
									local posKeys = if not XMLSource.chkTimeRange.checked or (XMLSource.chkTimeRange.checked and XMLSource.spFrames.value > 0) then gXmlAnIO.getNodePosKeys idx else 0

									if posKeys > 0 then
									(
										local firstKey = gXmlAnIO.getNodePosKeyFrame idx 0
										local timeOffset = if XMLSource.chkTimeRange.checked then (if XMLSource.spStartTime.value >= firstkey then abs(XMLSource.spStartTime.value - firstKey) else -abs(firstKey - XMLSource.spStartTime.value)) else 0
										local lastKey = if XMLSource.chkTimeRange.checked then firstKey + timeOffset + (XMLSource.spFrames.value - 1) else gXmlAnIO.getNodePosKeyFrame idx (posKeys - 1)

										join ar_keys #(firstKey + timeOffset, lastKey)

										local zeroKey = isZeroKey obj.position.controller posKeys firstKey

										for j = 0 to posKeys - 1 do
										(
											local key = if XMLSource.chkTimeRange.checked then (gXmlAnIO.getNodePosKeyFrame idx j) + timeOffset else gXmlAnIO.getNodePosKeyFrame idx j

											if lastKey >= key then
											(
												local keys = gXmlAnIO.getNodePosKeyXYZ idx j

												at time key obj.position.controller.x_position = (keys[1] as float)
												at time key obj.position.controller.y_position = (keys[2] as float)
												at time key obj.position.controller.z_position = (keys[3] as float)

												if classof objRef == Biped_Object then at time key biped.setTransform objRef #pos obj.transform.position true
											)
										)

										if zeroKey then deleteKey obj.position.controller 1
									)
								)
							)

							if XMLSource.chkRotation.checked then
							(
								local rotKeys = if not XMLSource.chkTimeRange.checked or (XMLSource.chkTimeRange.checked and XMLSource.spFrames.value > 0) then gXmlAnIO.getNodeRotKeys idx else 0

								if rotKeys > 0 then
								(
									local firstKey = gXmlAnIO.getNodeRotKeyFrame idx 0
									local timeOffset = if XMLSource.chkTimeRange.checked then (if XMLSource.spStartTime.value >= firstkey then abs(XMLSource.spStartTime.value - firstKey) else -abs(firstKey - XMLSource.spStartTime.value)) else 0
									local lastKey = if XMLSource.chkTimeRange.checked then firstKey + timeOffset + (XMLSource.spFrames.value - 1) else gXmlAnIO.getNodeRotKeyFrame idx (rotKeys - 1)

									join ar_keys #(firstKey + timeOffset, lastKey)

									local zeroKey = isZeroKey obj.rotation.controller rotKeys firstKey

									for j = 0 to rotKeys - 1 do
									(
										local key = if XMLSource.chkTimeRange.checked then (gXmlAnIO.getNodeRotKeyFrame idx j) + timeOffset else gXmlAnIO.getNodeRotKeyFrame idx j

										if lastKey >= key then
										(
											local keys = gXmlAnIO.getNodeRotKeyXYZ idx j

											at time key obj.rotation.controller.x_rotation = (keys[1] as float)
											at time key obj.rotation.controller.y_rotation = (keys[2] as float)
											at time key obj.rotation.controller.z_rotation = (keys[3] as float)

											if classof objRef == Biped_Object then at time key biped.setTransform objRef #rotation (obj.transform.rotation as eulerangles) true
										)
									)

									if zeroKey then deleteKey obj.rotation.controller 1
								)
							)
						)

						if classof objRef == Biped_Object then delete obj
					)
				)

				if XMLSource.rbCtrl.state == 1 then animationRange = interval (amin ar_keys) (amax ar_keys)

				clearlistener()
				gXmlAnIO.print()

				gXmlAnIO.clear()

				enablesceneredraw()
				redrawviews()

				closeRolloutFloater GTA_Anim_Map
			)
			else
			(
				messageBox "No object has been matched yet!" title:"Error"
			)
		)
		else
		(
			messagebox "No animation has been loaded yet!" title:"Error"
		)
	)--end on btnLoadMotion
)--end rollout XMLMap

if GTA_Anim_Map != undefined then closeRolloutFloater GTA_Anim_Map
if GTA_Anim != undefined then closeRolloutFloater GTA_Anim
openAnimDialog()
