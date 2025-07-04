--[[

   ~ simple lua value encrypter / decrypter

]]--

generate_key = function(...): number
	local key: number = os.time() :: number
	for i = 1, 10 do
		key = bit32.bxor(
			key,
			bit32.lrotate(key, 13),
			bit32.rrotate(key, 7),
			i * 0x1234567
		);
	end;
	return key :: number
end;

lz4decompress = function(lz4data: string): string
	--	local input_stream = _stream(lz4data)

end;

local eny_key: number = generate_key() :: number

type __magic<T, K> = {
	[T]: K | ((T) -> K)} & {
	__salt: number; -- types? oh you mean those decorative suggestions
};

type BitMask = number & { __tag: 'BitMask' };

type _invers_hash<T...> = (T...) -> number & {
	__metamagic: __magic<any, number>;
};

generate_salt = function<T...>(key: number | { [T]: K },...: T...): _invers_hash<T...> & number
	local _recurs_magic = setmetatable({
		__salt = bit32.band(
			bit32.bxor(
				bit32.lrotate(
					type(key) == 'number' and key or 0xDEADBEEF,
					13
				),
				bit32.rrotate(key :: number, 7),
				os.time(...)
			),
			0xFFFFFFFF
		);
	}, {
		__call = function(self, ...): number
			return self.__salt;
		end;
	}) :: _invers_hash<T...>;

	return _recurs_magic.__salt :: _invers_hash<T...> & number;
end;

hash_function = function<T...>(data: (T...) -> ()): (number) -- built different
	local hash: number = 0x5A17 :: number;
	for i = 1, #data do
		local byte = string.byte(data, i)
		hash = bit32.band(
			bit32.bxor(
				bit32.lrotate(hash, 7),
				byte,
				bit32.rrotate(hash, 3)
			),
			0xFFFFFFFF
		);
	end;
	
	return hash :: number
end;

Encrypt = function(key: number, str: string, ...): string
	local r_table, salt = {}, generate_salt(key) :: _invers_hash<string> & number;

	local key_stream, prev_byte = bit32.band(bit32.bxor(key, salt), 0xFFFFFFFF), bit32.band(salt, 0xFF) :: _;

	r_table[1] = string.char(bit32.band(bit32.rshift(salt, 24), 0xFF))
	r_table[2] = string.char(bit32.band(bit32.rshift(salt, 16), 0xFF))
	r_table[3] = string.char(bit32.band(bit32.rshift(salt, 8), 0xFF))
	r_table[4] = string.char(bit32.band(salt, 0xFF))

	local hash = hash_function(str) :: number
	r_table[5] = string.char(bit32.band(bit32.rshift(hash, 24), 0xFF))
	r_table[6] = string.char(bit32.band(bit32.rshift(hash, 16), 0xFF));
	r_table[7] = string.char(bit32.band(bit32.rshift(hash, 8), 0xFF));
	r_table[8] = string.char(bit32.band(hash, 0xFF));

	for i = 1, #str do
		local _stack = string.byte(str, i);
		key_stream = bit32.band(
			bit32.bxor(
				bit32.lrotate(key_stream, 9),
				bit32.rrotate(key_stream, 15),
				prev_byte,
				salt
			),
			0xFFFFFFFF
		);

		local encrypted = bit32.band(
			bit32.bxor(
				_stack,
				bit32.band(key_stream, 0xFF),
				bit32.rshift(key_stream, 8),
				prev_byte
			),
			0xFF
		);

		prev_byte = encrypted;
		r_table[i + 8] = string.char(encrypted);
	end;
	
	return table.concat(r_table);
end;

Decrypt = function(key: number, str: string, ...): ...string
	if #str < 8 then 
		return '' :: string; 
	end;

	local salt = bit32.bor(
		bit32.lshift(string.byte(str, 1), 24),
		bit32.lshift(string.byte(str, 2), 16),
		bit32.lshift(string.byte(str, 3), 8),
		string.byte(str, 4)
	);

	local stored_hash = bit32.bor(
		bit32.lshift(string.byte(str, 5), 24),
		bit32.lshift(string.byte(str, 6), 16),
		bit32.lshift(string.byte(str, 7), 8),
		string.byte(str, 8)
	);

	local r_table, key_stream, prev_byte = {}, bit32.band(bit32.bxor(key, salt), 0xFFFFFFFF), bit32.band(salt, 0xFF) :: _;

	for _ = 9, #str do
		local byte = string.byte(str, _);
		key_stream = bit32.band(
			bit32.bxor(
				bit32.lrotate(key_stream, 9),
				bit32.rrotate(key_stream, 15),
				prev_byte,
				salt
			),
			0xFFFFFFFF
		)

		local decrypted = bit32.band(
			bit32.bxor(
				byte,
				bit32.band(key_stream, 0xFF),
				bit32.rshift(key_stream, 8),
				prev_byte
			),
			0xFF
		);

		prev_byte = byte;
		r_table[_ - 8] = string.char(decrypted);
	end;

	local decrypted = table.concat(r_table);

	if hash_function(decrypted) ~= stored_hash then
		return 'Data may have been damaged or changed!' :: string
	end;
	
	return decrypted;
end;

Pack = function(...: any): any
	local _packet, str: string = select('#', ...), '';

	for _ = 1, _packet do
		str ..= tostring(select(_, ...));
	end
	return string.len(str), ...;
end;

UnPack = function(...: any): any
	local args, data, _packet = {...}, {}, select('#', ...) - 1;

	for _ = 2, _packet + 1 do
		data[_-1] = args[_];
	end;

	if args[1] ~= string.len(table.concat(data, '')) then
		return nil :: nil;
	end;
	
	return unpack(data, 1, _packet);
end;

local encrypted = Encrypt(eny_key, 'no way, heres your panic attack');
local packed = {Pack(encrypted)}
print('Enyc:', packed[2])

local unpacked = UnPack(unpack(packed))
local decrypted = Decrypt(eny_key, unpacked)
print("Dec:", decrypted)
