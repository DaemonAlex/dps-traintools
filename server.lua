RegisterNetEvent('dps-traintools:seatmark', function(line)
    if type(line) ~= 'string' or #line > 200 then return end
    print(('[seatmark] %s: %s'):format(GetPlayerName(source), line))
end)
