s = selection as array
clearSelection ()

for i = 1 to s.count do
 (
  new_ob = copy s[i]
  new_ob.name = s[i].name
  selectmore new_ob
  setUserPropBuffer new_ob (getUserPropBuffer s[i])
 )
 