s = selection as array
clearSelection ()

for i = 1 to s.count do
 (
  new_ob = copy s[i]
  new_ob.name = "lod" + (substring s[i].name 4 -1)
  selectmore new_ob
  setUserPropBuffer new_ob (getUserPropBuffer s[i])
 )
 