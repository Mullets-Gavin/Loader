// Loader TypeScript typings for Roblox-TS
declare class Subscription {
	Unsubscribe(): Subscription;
}

declare class DataSyncFile {
	Loaded(): boolean;
	Ready(): boolean;
	GetData(value: string | number | void): unknown;
	UpdateData(value: string, data: unknown | void): this;
	IncrementData(value: string, num: number): this;
	SaveData(): this;
	RemoveData(): this;
	WipeData(): this;
}

declare class DataSyncStore {
	FilterKeys(keys: Array<string>, filter: boolean | void): this;
	GetFile(index: string | number | void): DataSyncFile;
	Subscribe(
		index: string | number | Player,
		value: string | Array<unknown>,
		code: (data: Array<unknown>) => void,
	): Subscription;
}

interface DataSync {
	GetStore: (key: string, data: Array<unknown> | void) => DataSyncStore;
}

interface Manager {
	Wait: (clock: number) => number;
}

interface Network {
	CreateEvent: (name: string) => RemoteEvent;
	CreateFunction: (name: string) => RemoteFunction;
	CreateBindableEvent: (name: string) => BindableEvent;
	CreateBindableFunction: (name: string) => BindableFunction;

	HookEvent(name: string, code: () => void): RemoteEvent;
	HookFunction(name: string, code: () => void): RemoteFunction;
	UnhookEvent(): boolean;
	UnhookFunction(): boolean;

	FireServer: (name: string, ...args: unknown[]) => void;
	FireClient: (name: string, client: Player, ...args: unknown[]) => void;
	FireClients: (name: string, clients: Array<Player>, ...args: unknown[]) => void;
	FireAllClients: (name: string, ...args: unknown[]) => void;

	InvokeServer(name: string, ...args: unknown[]): unknown[];
	InvokeClient(name: string, client: Player, ...args: unknown[]): unknown[];
	InvokeAllClients(name: string, ...args: unknown[]): unknown[];

	BindEvent(name: string): BindableEvent;
	BindFunction(name: string): BindableFunction;
	UnbindEvent(name: string): boolean;
	UnbindFunction(name: string): boolean;

	FireBindable: (name: string, ...args: unknown[]) => void;
	InvokeBindable(name: string, ...args: unknown[]): unknown[];
}

declare class AssignSizesObject {
	Update(scale: number, min: number, max: number): this;
	Changed(code: () => void): this;
	Disconnect(): this;
}

declare class RichTextObject {
	Append(value: string | Array<unknown>): this;
	Bold(state: boolean): this;
	Italic(state: boolean): this;
	Underline(state: boolean): this;
	Strike(state: boolean): this;
	Comment(state: boolean): this;
	Font(state: string | EnumItem | boolean): this;
	Size(number: number | boolean): this;
	Color(color: Color3 | boolean): this;
	GetRaw(): string;
	GetText(): string;
}

declare class KeybindObject {
	Enabled(state: boolean): void;
	Keybinds(...args: EnumItem[]): void;
	Mobile(state: boolean, image: string | void): void;
	Hook(code: () => void): void;
	Destroy(): void;
}

interface Interface {
	IsComputer: () => boolean;
	IsMobile: () => boolean;
	IsConsole: () => boolean;
	IsKeyboard: () => boolean;
	IsMouse: () => boolean;
	IsTouch: () => boolean;
	IsGamepad: () => boolean;
	IsVR: () => boolean;

	AssignSizes: () => AssignSizesObject;
	RichText: () => RichTextObject;
	Keybind: () => KeybindObject;

	Disconnect(name: string): void;
	Update(name: string, keys: Array<EnumItem>): boolean;
	Began(name: string, keys: Array<EnumItem>, code: () => void): void;
	Ended(name: string, keys: Array<EnumItem>, code: () => void): void;
	Tapped(name: string, code: () => void): void;
}

interface Roblox {
	PromptFriendRequest(toPlayer: Player): unknown | boolean;
	PromptUnfriendRequest(toPlayer: Player): unknown | boolean;
	PromptBlockRequest(toPlayer: Player): unknown | boolean;
	PromptUnblockRequest(toPlayer: Player): unknown | boolean;
	PromptGameInvite(player: Player): unknown | boolean;

	GetFriends(player: Player): unknown | boolean;
	GetBlocked(): unknown | boolean;
	GetRankInGroup(player: Player, group: number): unknown | boolean;
	GetFriendsOnline(player: Player, num: number | void): unknown | boolean;
	GetUserHeadshot(userId: number, enumSize: EnumItem | void): unknown | boolean;
	GetUserBust(userId: number, enumSize: EnumItem | void): unknown | boolean;
	GetUserAvatar(userId: number, enumSize: EnumItem | void): unknown | boolean;
	GetUserTeleportInfo(userId: number): unknown | boolean;

	IsFriendsWith(player: Player, userId: number): boolean;
	IsBlockedWith(player: Player, userId: number): boolean;
	IsGameCreator(player: Player): boolean;

	CanSendGameInviteAsync(player: Player): boolean;

	FilterText(text: string, userId: number, context: EnumItem | void): unknown | boolean;
	FilterChatForUser(filter: Instance, toUserId: number): unknown | boolean;
	FilterStringForUser(filter: Instance, toUserId: number): unknown | boolean;
	FilterStringForBroadcast(filter: Instance): unknown | boolean;

	PostNotification(properties: Array<unknown>): unknown | boolean;
	PostNotification(assets: Array<Instance>, code: () => void | void): unknown | boolean;
}

interface Loader {
	require(this: void, module: "Interface"): Interface;
	require(this: void, module: "DataSync"): DataSync;
	require(this: void, module: "Manager"): Manager;
	require(this: void, module: "Network"): Network;
	require(this: void, module: "Roblox"): Roblox;

	server(this: void, module: "Interface"): Interface;
	server(this: void, module: "DataSync"): DataSync;
	server(this: void, module: "Manager"): Manager;
	server(this: void, module: "Network"): Network;
	server(this: void, module: "Roblox"): Roblox;

	server(this: void, module: "Interface"): Interface;
	server(this: void, module: "DataSync"): DataSync;
	server(this: void, module: "Manager"): Manager;
	server(this: void, module: "Network"): Network;
	server(this: void, module: "Roblox"): Roblox;

	enum: (name: string, members: string[]) => string[];
}

declare const Loader: Loader;
export = Loader;
