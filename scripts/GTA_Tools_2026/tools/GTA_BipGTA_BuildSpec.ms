global GTA_BipGTA_PrintBuildSpec
global GTA_BipGTA_SaveBuildSpec

fn GTA_BipGTA_BuildSpecText = (
    local report = stringStream ""

    format "BipGTA Build Spec\n" to:report
    format "Derived from: research\\gta_skeleton_dump.txt\n\n" to:report

    format "Goal\n" to:report
    format "- Build a stable target biped-like transfer rig that matches the default SA player skeleton as closely as practical.\n" to:report
    format "- Keep optional expressive bones present only in the GTA dummy hierarchy, not in the default BipGTA transfer target.\n" to:report
    format "- Use BoneID as the authoritative identity for GTA matching.\n\n" to:report

    format "Scene Roles\n" to:report
    format "1. BipBVH: source rig that is allowed to restructure to match incoming BVH/FBX.\n" to:report
    format "2. BipGTA: stable target rig used for reduction/blending before bake to GTA dummies.\n" to:report
    format "3. GTA dummy hierarchy: BoneID-driven export rig loaded from the character tools.\n\n" to:report

    format "Default GTA Root Notes\n" to:report
    format "- BoneID 0 is the real root identity.\n" to:report
    format "- Imported root names can be Root, Normal, Fat, or Ripped.\n" to:report
    format "- Community ped assets often use Root, but player.dff commonly imports as Normal.\n\n" to:report

    format "Recommended BipGTA Core Chain (include by default)\n" to:report
    format "Depth\tBoneID\tGTA Node\tRecommended BipGTA Target\n" to:report
    format "0\t0\tNormal/Root alias\tBip root object\n" to:report
    format "1\t1\tPelvis\tBip Pelvis\n" to:report
    format "2\t2\tSpine\tBip Spine\n" to:report
    format "3\t3\tSpine1\tBip Spine1\n" to:report
    format "4\t4\tNeck\tBip Neck\n" to:report
    format "5\t5\tHead\tBip Head\n" to:report
    format "5\t31\tBip01 L Clavicle\tBip L Clavicle\n" to:report
    format "6\t32\tL UpperArm\tBip L UpperArm\n" to:report
    format "7\t33\tL ForeArm\tBip L ForeArm\n" to:report
    format "8\t34\tL Hand\tBip L Hand\n" to:report
    format "9\t35\tL Finger\tBip L Finger0\n" to:report
    format "10\t36\tL Finger01\tBip L Finger01\n" to:report
    format "5\t21\tBip01 R Clavicle\tBip R Clavicle\n" to:report
    format "6\t22\tR UpperArm\tBip R UpperArm\n" to:report
    format "7\t23\tR ForeArm\tBip R ForeArm\n" to:report
    format "8\t24\tR Hand\tBip R Hand\n" to:report
    format "9\t25\tR Finger\tBip R Finger0\n" to:report
    format "10\t26\tR Finger01\tBip R Finger01\n" to:report
    format "2\t41\tL Thigh\tBip L Thigh\n" to:report
    format "3\t42\tL Calf\tBip L Calf\n" to:report
    format "4\t43\tL Foot\tBip L Foot\n" to:report
    format "5\t44\tL Toe0\tBip L Toe0\n" to:report
    format "2\t51\tR Thigh\tBip R Thigh\n" to:report
    format "3\t52\tR Calf\tBip R Calf\n" to:report
    format "4\t53\tR Foot\tBip R Foot\n" to:report
    format "5\t54\tR Toe0\tBip R Toe0\n\n" to:report

    format "Optional GTA Bones (exclude from default mapping/export)\n" to:report
    format "BoneID\tGTA Node\tDefault Policy\n" to:report
    format "201\tBelly\tKeep on GTA dummy hierarchy; do not animate by default.\n" to:report
    format "301\tR breast\tKeep on GTA dummy hierarchy; do not animate by default.\n" to:report
    format "302\tL breast\tKeep on GTA dummy hierarchy; do not animate by default.\n" to:report
    format "8\tJaw\tKeep on GTA dummy hierarchy; do not animate by default.\n" to:report
    format "6\tL Brow\tKeep on GTA dummy hierarchy; do not animate by default.\n" to:report
    format "7\tR Brow\tKeep on GTA dummy hierarchy; do not animate by default.\n\n" to:report

    format "BipGTA Construction Rules\n" to:report
    format "- Keep BipGTA aligned at world origin for bake/export.\n" to:report
    format "- Keep canonical Biped naming; do not rename every child bone.\n" to:report
    format "- Use two spine links in the torso exactly as dumped: Spine -> Spine1.\n" to:report
    format "- Include toe and finger chains in the default build because player.dff uses them.\n" to:report
    format "- Do not add Belly/Jaw/Brow/Breast bones to BipGTA unless making a separate expressive profile.\n\n" to:report

    format "Default Mapping Policy\n" to:report
    format "- Map 26 core bones by default.\n" to:report
    format "- Ignore 6 optional expressive bones by default.\n" to:report
    format "- Root translation goes to BoneID 0 root; hips rotation goes to Pelvis (BoneID 1).\n" to:report
    format "- BoneID is authoritative; node name is a heuristic only.\n\n" to:report

    format "Recommended Loading / Use\n" to:report
    format "1. fileIn (scriptsPath + \"GTA_Tools_2026\\tools\\GTA_BipGTA_BuildSpec.ms\")\n" to:report
    format "2. GTA_BipGTA_PrintBuildSpec()\n" to:report
    format "3. Optional: GTA_BipGTA_SaveBuildSpec()\n\n" to:report

    format "Next Practical Step\n" to:report
    format "- Build BipGTA with the 26 core targets above, then skin the transfer mesh to that rig.\n" to:report

    (report as string)
)

fn GTA_BipGTA_PrintBuildSpec = (
    clearListener()
    format "%" (GTA_BipGTA_BuildSpecText())
    true
)

fn GTA_BipGTA_SaveBuildSpec outPath:undefined = (
    local targetPath = outPath
    if targetPath == undefined then (
        targetPath = getSaveFileName caption:"Save BipGTA Build Spec" filename:"BipGTA_BuildSpec.txt" types:"Text File (*.txt)|*.txt|All Files (*.*)|*.*|"
    )
    if targetPath == undefined then return false

    local outFile = createFile targetPath
    format "%" (GTA_BipGTA_BuildSpecText()) to:outFile
    close outFile
    true
)

format "BipGTA Build Spec loaded.\n"
format "Use GTA_BipGTA_PrintBuildSpec() or GTA_BipGTA_SaveBuildSpec().\n"