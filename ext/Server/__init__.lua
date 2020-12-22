require('events')

Events:Subscribe('Partition:Loaded', OnPartitionLoaded)
Events:Subscribe('Engine:Update', OnEngineUpdate)
Events:Subscribe('Level:Loaded', OnLevelLoaded)