extends newBodyAPI 
class_name glintBodyAPI
#for objects which are too small to be visually represented, and are thus shown as the default 'glint' texture on the system map and scopes!

#to inherit this, the class must contain original methods or variables which are
#A: of a type which you would feel unsafe cramming into metadata - e.g, object or texture
#B: are modified constantly during gameplay
