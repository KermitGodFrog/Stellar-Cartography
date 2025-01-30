extends newBodyAPI
class_name customBodyAPI

#unsure what kind of variables this one will have yet:
#texture pointer for system map, mesh pointer for scopes...

#to inherit this, the class must contain original methods or variables which are
#A: of a type which you would feel unsafe cramming into metadata - e.g, object or texture
#B: are modified constantly during gameplay
