--[[
   Roblox Luau

   Simple bypass of the filter in the roblox chat  </>
   
   Server Side

]]--

local ReplicatedStorage: ReplicatedStorage, Chat: Chat = game:GetService('ReplicatedStorage'), game:GetService('Chat') :: _;
local Event: RemoteEvent = ReplicatedStorage:WaitForChild('CHAT') :: RemoteEvent;

function bubble(player: Player, message: string, ...): (_)
	local player_char: Model = player.Character or player.CharacterAdded:Wait() :: Model;
	local player_head: BasePart = player_char:FindFirstChild('Head') :: BasePart;
	
	if player_head then
		Chat:Chat(player_head, message);
	end;
end;

if Event then
	Event.OnServerEvent:Connect(function(...): (_)
		task.spawn(bubble, ...);
		Event:FireAllClients(...);
	end);
end;


--[[

   Simple bypass of the filter in the roblox chat  </>
   
   Client Side

]]--

if not game.Loaded then
	game.Loaded:Wait();
end;

local TextChatService: TextChatService, Players: Players, ReplicatedStorage: ReplicatedStorage = game:GetService('TextChatService'), game:GetService('Players'), game:GetService('ReplicatedStorage') :: _;
local Event: RemoteEvent = ReplicatedStorage:WaitForChild('CHAT') :: RemoteEvent;
local RBXSystem: TextChannel = TextChatService:WaitForChild('TextChannels'):WaitForChild('RBXSystem') :: TextChannel;

if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
	error'Does not support other chat versions, select ChatVersion.TextChatService';
end;

function name_to_hex(name: string): string
	if not name then 
		return '#FFFFFF' :: string; 
	end;
	
	local r, g, b = 0, 0, 0;
	
	for i = 1, #name do 
		local byte = string.byte(name, i) :: _;
		if i % 3 == 1 then 
			r = (r + byte) % 256;
		elseif i % 3 == 2 then 
			g = (g + byte) % 256;
		else 
			b = (b + byte) % 256 
		end;
	end; 
	return string.format(`#%02X%02X%02X`, r, g, b) :: string;
end;

Event.OnClientEvent:Connect(function(player: Player, message: string, player_name: string) : (_)
	if player then
		RBXSystem:DisplaySystemMessage(`[❤️] <font color=\'{name_to_hex(player_name)}\'>{player_name}</font> <font color='#ffffff'>{message}</font>`);
	end;
end);

TextChatService.OnIncomingMessage = function(message: TextChatMessage): (_)
	if message.Status == Enum.TextChatMessageStatus.Sending then
		if message.TextSource then 
			Event:FireServer(message.Text, message.TextSource.Name);
			message.Text = '' :: string;
		end;
	end;
end;

--TextChatService.OnIncomingMessage = function(message: TextChatMessage): (_) -- old implementation
--	local prop: TextChatMessageProperties = Instance.new('TextChatMessageProperties', nil) :: TextChatMessageProperties;

--	if message.TextSource then 
--		if not message.Text:match('^%[❤️%]') then
--			Event:FireServer(message.Text, message.TextSource.Name);
--		end;
--		prop.Text, prop.PrefixText = nil, nil :: nil
--	end;

--	return prop;
--end;
