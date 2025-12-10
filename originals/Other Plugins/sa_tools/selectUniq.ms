news = #()
newn = #()
s = $

news[1] = s[1]
newn[1] = s[1].name

for i = 2 to s.count do 
 if (findItem newn s[i].name) == 0 do (
  append news s[i]
  append newn s[i].name
 )
  
clearSelection()

for i = 1 to news.count do selectMore news[i]