Events:Subscribe('Extension:Loaded', function()
    WebUI:Init()
end)

Events:Subscribe('Level:Loaded', function(levelName, gameMode)
    WebUI:ExecuteJS('audio = document.getElementById(\'audio_play\'); audio.play()')
end)

NetEvents:Subscribe('Chaos:Knifed', function()
    WebUI:ExecuteJS('audio = document.getElementById(\'audio_knifed\'); audio.play()')
end)