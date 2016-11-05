module level;

import std.algorithm;
import std.string;
import std.conv;
import std.json;
import std.regex;
import std.digest.md;
import std.stdio;

import avocado.core;
import avocado.dfs;

import asdf;
import components;
import app;

enum VarType : ubyte {
	invalid,
	enemy,
	label,
	flag
}

struct Variable {
	VarType type;
	string name;
	union {
		size_t index;
		bool enabled;
	}
}

enum TaskType : ubyte {
	invalid,
	sleep,
	waitClear,
	toast,
	test,
	go,
	spawn
}

struct Task {
	TaskType type;
	union {
		float time;
		size_t index;
		ubyte[] arguments;
	}
}

private struct EnemyEvent {
	string type;
	ubyte[16] other;
	Enemy modifications;
}

private struct EnemyComponent {
	Enemy enemy;
	mixin ComponentBase;
}

private final class Enemy {
	string name;
	bool hasDisplay;
	EntityDisplay display;
	bool hasAxisVelocity;
	AxisVelocity axisVelocity;
	bool hasLinearVelocity;
	LinearVelocity linearVelocity;
	bool hasAngularVelocity;
	AngularVelocity angularVelocity;
	bool hasAxisDamping;
	AxisDamping axisDamping;
	bool hasLinearDamping;
	LinearDamping linearDamping;
	bool hasAngularDamping;
	AngularDamping angularDamping;
	bool hasHealth;
	Health health;
	bool hasBullets;
	BulletSpawner bullets;
	bool hasCollisions;
	Collisions collisions;
	EnemyEvent[] onSecond;
	EnemyEvent[] onDeath;

	Enemy dup() {
		Enemy enemy = new Enemy();
		enemy.name = name; // no changes
		enemy.hasDisplay = hasDisplay; // no changes
		enemy.display = display; // no changes
		enemy.hasAxisVelocity = hasAxisVelocity;
		enemy.axisVelocity = axisVelocity.dup;
		enemy.hasLinearVelocity = hasLinearVelocity;
		enemy.linearVelocity = linearVelocity.dup;
		enemy.hasAngularVelocity = hasAngularVelocity;
		enemy.angularVelocity = angularVelocity.dup;
		enemy.hasAxisDamping = hasAxisDamping; // no changes
		enemy.axisDamping = axisDamping; // no changes
		enemy.hasLinearDamping = hasLinearDamping; // no changes
		enemy.linearDamping = linearDamping; // no changes
		enemy.hasAngularDamping = hasAngularDamping; // no changes
		enemy.angularDamping = angularDamping; // no changes
		enemy.hasHealth = hasHealth;
		enemy.health = health.dup;
		enemy.hasBullets = hasBullets;
		enemy.bullets = bullets.dup;
		enemy.hasCollisions = hasCollisions; // no changes
		enemy.collisions = collisions; // no changes
		enemy.onSecond = onSecond;
		enemy.onDeath = onDeath;
		return enemy;
	}

	Enemy merge(Enemy other) {
		if (other.hasAxisVelocity) {
			hasAxisVelocity = true;
			axisVelocity = other.axisVelocity;
		}
		if (other.hasLinearVelocity) {
			hasLinearVelocity = true;
			linearVelocity = other.linearVelocity;
		}
		if (other.hasAngularVelocity) {
			hasAngularVelocity = true;
			angularVelocity = other.angularVelocity;
		}
		if (other.hasHealth) {
			hasHealth = true;
			health = other.health;
		}
		if (other.hasBullets) {
			hasBullets = true;
			bullets = other.bullets;
		}
		return this;
	}

	Entity spawn(World world, float x, float y) {
		Entity entity = world.newEntity(name);
		if (hasDisplay)
			entity.set!EntityDisplay(&display);
		if (hasAxisVelocity)
			entity.set!AxisVelocity(&axisVelocity);
		if (hasLinearVelocity)
			entity.set!LinearVelocity(&linearVelocity);
		if (hasAngularVelocity)
			entity.set!AngularVelocity(&angularVelocity);
		if (hasAxisDamping)
			entity.set!AxisDamping(&axisDamping);
		if (hasLinearDamping)
			entity.set!LinearDamping(&linearDamping);
		if (hasAngularDamping)
			entity.set!AngularDamping(&angularDamping);
		if (hasHealth)
			entity.set!Health(&health);
		if (hasBullets)
			entity.set!BulletSpawner(&bullets);
		if (hasCollisions)
			entity.set!Collisions(&collisions);
		entity.add!Position(vec2(x, y), 0);
		entity.add!Boxed(FixAction.wrapXkillY);
		entity.add!EnemyComponent(this);
		entity.finalize();
		return entity;
	}

	Enemy compile(Asdf json) {
		if (json["name"] != Asdf.init)
			name = json["name"].get("");
		if (json["display"] != Asdf.init) {
			hasDisplay = true;
			display = deserialize!EntityDisplayJson(json["display"]).create;
		}
		if (json["axisVelocity"] != Asdf.init) {
			hasAxisVelocity = true;
			axisVelocity = deserialize!AxisVelocityJson(json["axisVelocity"]).create;
		}
		if (json["linearVelocity"] != Asdf.init) {
			hasLinearVelocity = true;
			linearVelocity = deserialize!LinearVelocityJson(json["linearVelocity"]).create;
		}
		if (json["angularVelocity"] != Asdf.init) {
			hasAngularVelocity = true;
			angularVelocity = deserialize!AngularVelocity(json["angularVelocity"]);
		}
		if (json["axisDamping"] != Asdf.init) {
			hasAxisDamping = true;
			axisDamping = deserialize!AxisDampingJson(json["axisDamping"]).create;
		}
		if (json["linearDamping"] != Asdf.init) {
			hasLinearDamping = true;
			linearDamping = deserialize!LinearDampingJson(json["linearDamping"]).create;
		}
		if (json["angularDamping"] != Asdf.init) {
			hasAngularDamping = true;
			angularDamping = deserialize!AngularDamping(json["angularDamping"]);
		}
		if (json["health"] != Asdf.init) {
			hasHealth = true;
			health = deserialize!Health(json["health"]);
		}
		if (json["bullets"] != Asdf.init) {
			hasBullets = true;
			bullets = deserialize!BulletSpawner(json["bullets"]);
		}
		if (json["collisions"] != Asdf.init) {
			hasCollisions = true;
			collisions = deserialize!CollisionsJson(json["collisions"]).create;
		}
		if (json["events", "onSecond"] != Asdf.init)
			foreach (event; json["events"]["onSecond"].byElement)
				onSecond ~= EnemyEvent(event["type"].get(""), event["entity"].get("").md5Of, new Enemy().compile(event));
		if (json["events", "onDeath"] != Asdf.init)
			foreach (event; json["events"]["onDeath"].byElement)
				onDeath ~= EnemyEvent(event["type"].get(""), event["entity"].get("").md5Of, new Enemy().compile(event));
		return this;
	}

	static Enemy fromFile(ResourceManager res, string file) {
		auto enemy = new Enemy();
		auto text = res.load!TextProvider(file);
		return enemy.compile(parseJson(text.value));
	}
}

private float timeFromStr(string line, size_t lnNo) {
	if (line == "inf")
		return float.infinity;
	string amount = line.munch("0123456789.");
	float length = 0;
	try {
		length = amount.to!float;
	}
	catch (Exception e) {
		throw new Exception("Invalid wait format in line " ~ lnNo.to!string);
	}
	switch (line.toLower) {
	case "s":
	case "sec":
	case "second":
		break;
	case "ms":
	case "millisecond":
	case "milliseconds":
		length *= 0.001f;
		break;
	case "min":
	case "mins":
	case "minute":
	case "minutes":
		length *= 60;
		break;
	default:
		throw new Exception("Unknown time unit in line " ~ lnNo.to!string);
	}
	return length;
}

string parseCString(string rawValue, size_t lnNo) {
	if (rawValue.length == 0)
		throw new Exception("String has no value in line " ~ lnNo.to!string);
	if (rawValue[0] != '"')
		throw new Exception("Value must be a string in line " ~ lnNo.to!string);
	JSONValue json;
	try {
		json = parseJSON(rawValue);
	}
	catch (Exception e) {
		throw new Exception("Invalid string in line " ~ lnNo.to!string);
	}
	if (json.type != JSON_TYPE.STRING)
		throw new Exception("Value must be a string in line " ~ lnNo.to!string);
	return json.str;
}

enum VarCmpOp {
	None,
	Equal,
	NotEqual,
	LT,
	GT,
	LTE,
	GTE
}

final class Level {
	this(Game game, ResourceManager res, World world) {
		this.game = game;
		this.res = res;
		this.world = world;

		game.onEntityKilled ~= &resetLastEnemyOffscreen;
		game.onEntityOutOfBounds ~= &setLastEnemyOffscreen;
		game.onEntityGenericDeath ~= &onEnemyDeath;
	}

	void compile(string content) {
		tasks.length = 0;
		variables.length = 0;

		variables ~= Variable(VarType.flag, "lastEnemyOffscreen");
		variables ~= Variable(VarType.flag, "clearTimeout");

		Task t;
		Variable v;
		foreach (lnNo, line; content.splitLines) {
			processCommand(lnNo, line, t, v);
			if (v.type != VarType.invalid)
				variables ~= v;
			if (t.type != TaskType.invalid)
				tasks ~= t;
		}
	}

	static Level fromFile(Game game, ResourceManager res, World world, string file) {
		auto lvl = new Level(game, res, world);
		auto text = res.load!TextProvider(file);
		lvl.compile(text.value);
		return lvl;
	}

	bool update(float delta) {
		if (curTask >= tasks.length)
			return false;
		const Task task = tasks[curTask];
		runTask(delta, task);
		secondTime += delta;
		if (secondTime > 1) {
			secondTime -= 1;
			foreach (enemy; spawned)
				onSecond(enemy);
		}
		return true;
	}

	void runTask(float delta, ref in Task task) {
		final switch (task.type) {
		case TaskType.invalid:
			curTask++;
			break;
		case TaskType.go:
			curTask = task.index;
			break;
		case TaskType.sleep:
			curTime += delta;
			if (curTime > task.time) {
				curTask++;
				curTime = 0;
			}
			break;
		case TaskType.waitClear:
			variables[1].enabled = false;
			curTime += delta;
			if (curTime > task.time) {
				curTask++;
				curTime = 0;
				assert(variables[1].name == "clearTimeout");
				variables[1].enabled = true;
			}
			removeDeadSpawned();
			if (spawned.length == 0) {
				curTask++;
				curTime = 0;
			}
			break;
		case TaskType.toast:
			std.stdio.writeln("TOAST: ", task.arguments[4], ", ", cast(string)task.arguments[5 .. task.arguments[4] + 5]);
			curTask++;
			break;
		case TaskType.test:
			if (evalExpression(cast(string)task.arguments[2 .. 2 + task.arguments[0]])) {
				string cmd = cast(string)task.arguments[2 + task.arguments[0] .. $];
				Task t;
				Variable v;
				processCommand(0, cmd, t, v);
				assert(t.type != TaskType.invalid);
				runTask(delta, t);
			} else
				curTask++;
			break;
		case TaskType.spawn:
			int index = (cast(int*)task.arguments)[0];
			float x = (cast(float*)task.arguments)[1];
			float y = (cast(float*)task.arguments)[2];
			spawned ~= enemies[index].dup.spawn(world, x, y);
			curTask++;
			break;
		}
	}

private:
	void onEnemyDeath(Entity entity) {
		EnemyComponent enemyCom;
		Position position;
		if (entity.fetch(enemyCom, position)) {
			Enemy enemy = enemyCom.enemy;
			foreach (event; enemy.onDeath) {
				if (event.type == "spawn") {
					spawned ~= enemyFromHash(event.other).dup.merge(event.modifications).spawn(world, position.position.x, position.position.y);
				}
			}
		}
	}

	void onSecond(Entity entity) {
		if (!entity.alive)
			return;
		EnemyComponent enemyCom;
		Position position;
		if (entity.fetch(enemyCom, position)) {
			Enemy enemy = enemyCom.enemy;
			foreach (event; enemy.onSecond) {
				if (event.type == "spawn") {
					spawned ~= enemyFromHash(event.other).dup.merge(event.modifications).spawn(world, position.position.x, position.position.y);
				}
			}
		}
	}

	void resetLastEnemyOffscreen() {
		assert(variables[0].name == "lastEnemyOffscreen");
		variables[0].enabled = false;
	}

	void setLastEnemyOffscreen() {
		assert(variables[0].name == "lastEnemyOffscreen");
		variables[0].enabled = true;
	}

	void removeDeadSpawned() {
		foreach_reverse (i, ref entity; spawned) {
			if (!entity.alive)
				spawned = spawned.remove(i);
		}
	}

	void processCommand(size_t lnNo, ref string line, out Task t, out Variable v) {
		line = line.strip;
		if (line.startsWith("//"))
			return;
		if (line.length == 0)
			return;
		if (line.startsWith("enemy ")) { // define enemy
			line = line[6 .. $];
			auto sep = line.indexOf('=');
			if (sep == -1)
				throw new Exception("Invalid enemy declaration in line " ~ lnNo.to!string);
			string name = line[0 .. sep].strip;
			string rawValue = line[sep + 1 .. $].strip;
			string value = rawValue.parseCString(lnNo);
			size_t index = enemies.length;
			assert(index == enemyHashes.length);

			enemyHashes ~= name.md5Of;
			enemies ~= Enemy.fromFile(res, value);
			v = Variable(VarType.enemy, name);
			v.index = index;
		} else if (line.startsWith("label ")) { // define label
			string name = line[6 .. $].strip;
			v = Variable(VarType.label, name);
			v.index = tasks.length;
		} else if (line.startsWith("wait ")) {
			line = line[5 .. $].strip;
			auto orIndex = line.indexOf(" or ");
			if (orIndex != -1) {
				string lhs = line[0 .. orIndex].stripRight;
				string rhs = line[orIndex + 4 .. $].stripLeft;
				float amount;
				if (lhs == rhs)
					throw new Exception("Left and right side are identical in line " ~ lnNo.to!string);
				if (lhs != "clear" && rhs != "clear")
					throw new Exception("Can't choose between two fixed time amounts in line " ~ lnNo.to!string);
				if (lhs == "clear")
					amount = rhs.timeFromStr(lnNo);
				else
					amount = lhs.timeFromStr(lnNo);
				t = Task(TaskType.waitClear);
				t.time = amount;
			} else if (!line.canFind(' ')) {
				if (line == "clear") {
					t = Task(TaskType.waitClear);
					t.time = float.infinity;
				} else {
					t = Task(TaskType.sleep);
					t.time = line.timeFromStr(lnNo);
				}
			} else
				throw new Exception("Invalid wait format in line " ~ lnNo.to!string);
		} else if (line.startsWith("toast ")) {
			line = line[6 .. $].strip;
			auto sep = line.indexOf(",");
			if (sep == -1)
				throw new Exception("Invalid toast call in line " ~ lnNo.to!string);
			float time = line[0 .. sep].timeFromStr(lnNo);
			string text = line[sep + 1 .. $].strip.parseCString(lnNo);
			if (text.length >= ubyte.max)
				throw new Exception("Toast text too long in line " ~ lnNo.to!string);
			t = Task(TaskType.toast);
			t.arguments = [];
			t.arguments.length = 5 + text.length;
			t.arguments[0 .. 4] = (cast(ubyte*)&time)[0 .. 4];
			t.arguments[4] = cast(ubyte)text.length;
			t.arguments[5 .. $] = cast(ubyte[])text;
		} else if (line.startsWith("spawn ")) {
			line = line[6 .. $].strip;
			float x, y;
			string[] args = line.split(",");
			if (args.length != 3)
				throw new Exception("Wrong arguments for spawning entity in line " ~ lnNo.to!string);
			auto index = enemyIndexFromName(args[0].strip);
			if (index == -1)
				throw new Exception("No enemy named '" ~ args[0].strip ~ "' in line " ~ lnNo.to!string);
			try {
				x = args[1].strip.to!float;
				y = args[2].strip.to!float;
			}
			catch (Exception e) {
				throw new Exception("Wrong coordinate format in line " ~ lnNo.to!string);
			}
			t = Task(TaskType.spawn);
			t.arguments = [];
			t.arguments.length = 12;
			int iin = cast(int)index;
			t.arguments[0 .. 4] = (cast(ubyte*)&iin)[0 .. 4];
			t.arguments[4 .. 8] = (cast(ubyte*)&x)[0 .. 4];
			t.arguments[8 .. 12] = (cast(ubyte*)&y)[0 .. 4];
		} else if (line.startsWith("if ")) {
			line = line[3 .. $].strip;
			auto cmdLoc = line.indexOf(":");
			string expr = line[0 .. cmdLoc].strip;
			string cmd = line[cmdLoc + 1 .. $].strip;
			if (expr.length >= ubyte.max)
				throw new Exception("If-Expression too long in line " ~ lnNo.to!string);
			if (cmd.length >= ubyte.max)
				throw new Exception("Cmd-Expression too long in line " ~ lnNo.to!string);
			t = Task(TaskType.test);
			t.arguments = [];
			t.arguments.length = 2 + expr.length + cmd.length;
			t.arguments[0] = cast(ubyte)expr.length;
			t.arguments[1] = cast(ubyte)cmd.length;
			t.arguments[2 .. 2 + expr.length] = cast(ubyte[])expr;
			t.arguments[2 + expr.length .. $] = cast(ubyte[])cmd;
		} else if (line.startsWith("goto ")) {
			string label = line[5 .. $].strip;
			auto index = labelIndexFromName(label);
			if (index == -1)
				throw new Exception("No label called '" ~ label ~ "' in line " ~ lnNo.to!string);
			t = Task(TaskType.go);
			t.index = index;
		}
	}

	enum IdentifierRegex = ctRegex!`^[a-zA-Z_][a-zA-Z0-9_]*`;
	enum BooleanRegex = ctRegex!`^(?:true|false)`;
	bool evalExpression(string expr) {
		bool result = false;
		expr = expr.stripLeft;
		bool combineAnd;
		Variable lhs, rhs;
		VarCmpOp op;
		size_t lastLen = expr.length;
		while (expr.length) {
			expr = expr.stripLeft;
			if (auto match = expr.matchFirst(BooleanRegex)) {
				expr = expr[match[0].length .. $];
				Variable v = Variable(VarType.flag, "");
				v.enabled = match[0] == "true";
				if (lhs.type == VarType.invalid) {
					lhs = v;
				} else {
					rhs = v;
					if (op == VarCmpOp.None)
						throw new Exception("Syntax error in expression: " ~ expr);
					result = cmpVars(lhs, rhs, op, result, combineAnd);
					op = VarCmpOp.None;
					lhs.type = VarType.invalid;
					rhs.type = VarType.invalid;
				}
			} else if (auto match = expr.matchFirst(IdentifierRegex)) {
				expr = expr[match[0].length .. $];
				Variable var = variableFromName(match[0]);
				if (var.type == VarType.invalid)
					throw new Exception("No variable named '" ~ match[0] ~ "' in expression: " ~ expr);
				if (lhs.type == VarType.invalid) {
					lhs = var;
				} else {
					rhs = var;
					if (op == VarCmpOp.None)
						throw new Exception("Syntax error in expression: " ~ expr);
					result = cmpVars(lhs, rhs, op, result, combineAnd);
					op = VarCmpOp.None;
					lhs.type = VarType.invalid;
					rhs.type = VarType.invalid;
				}
			} else if (expr.startsWith("==")) {
				expr = expr[2 .. $];
				op = VarCmpOp.Equal;
			} else if (expr.startsWith("!=")) {
				expr = expr[2 .. $];
				op = VarCmpOp.NotEqual;
			} else if (expr.startsWith("<=")) {
				expr = expr[2 .. $];
				op = VarCmpOp.LTE;
			} else if (expr.startsWith(">=")) {
				expr = expr[2 .. $];
				op = VarCmpOp.GTE;
			} else if (expr.startsWith("<")) {
				expr = expr[1 .. $];
				op = VarCmpOp.LT;
			} else if (expr.startsWith(">")) {
				expr = expr[1 .. $];
				op = VarCmpOp.GT;
			} else if (expr.startsWith("&&")) {
				expr = expr[2 .. $];
				if (lhs.type != VarType.invalid)
					throw new Exception("Syntax error in expression: " ~ expr);
				combineAnd = true;
			} else if (expr.startsWith("||")) {
				expr = expr[2 .. $];
				if (lhs.type != VarType.invalid)
					throw new Exception("Syntax error in expression: " ~ expr);
				combineAnd = false;
			} else
				throw new Exception("Invalid expression: " ~ expr);
			if (expr.length == lastLen)
				throw new Exception("Stuck in parsing expression: " ~ expr);
			lastLen = expr.length;
		}
		return result;
	}

	bool cmpVars(Variable lhs, Variable rhs, VarCmpOp op, bool result, bool combineAnd) {
		if (combineAnd && !result)
			return false;
		if (!combineAnd && result)
			return true;
		if (lhs.type != rhs.type) {
			if (op == VarCmpOp.NotEqual)
				return true;
			if (combineAnd)
				return false;
			return result;
		}
		final switch (op) {
		case VarCmpOp.None:
			return result;
		case VarCmpOp.Equal:
			final switch (lhs.type) {
			case VarType.invalid:
				return true;
			case VarType.flag:
				return lhs.enabled == rhs.enabled;
			case VarType.enemy:
			case VarType.label:
				return lhs.index == rhs.index;
			}
		case VarCmpOp.NotEqual:
			final switch (lhs.type) {
			case VarType.invalid:
				return false;
			case VarType.flag:
				return lhs.enabled != rhs.enabled;
			case VarType.enemy:
			case VarType.label:
				return lhs.index != rhs.index;
			}
		case VarCmpOp.LT:
			final switch (lhs.type) {
			case VarType.invalid:
				return false;
			case VarType.flag:
				return lhs.enabled != rhs.enabled;
			case VarType.enemy:
			case VarType.label:
				return lhs.index < rhs.index;
			}
		case VarCmpOp.LTE:
			final switch (lhs.type) {
			case VarType.invalid:
				return true;
			case VarType.flag:
				return lhs.enabled == rhs.enabled;
			case VarType.enemy:
			case VarType.label:
				return lhs.index <= rhs.index;
			}
		case VarCmpOp.GT:
			final switch (lhs.type) {
			case VarType.invalid:
				return false;
			case VarType.flag:
				return lhs.enabled != rhs.enabled;
			case VarType.enemy:
			case VarType.label:
				return lhs.index > rhs.index;
			}
		case VarCmpOp.GTE:
			final switch (lhs.type) {
			case VarType.invalid:
				return true;
			case VarType.flag:
				return lhs.enabled == rhs.enabled;
			case VarType.enemy:
			case VarType.label:
				return lhs.index >= rhs.index;
			}
		}
	}

	size_t enemyIndexFromName(string name) {
		auto target = name.md5Of;
		foreach (i, ref hash; enemyHashes)
			if (hash == target)
				return i;
		return -1;
	}

	Enemy enemyFromHash(ubyte[16] target) {
		foreach (i, ref hash; enemyHashes)
			if (hash == target)
				return enemies[i];
		return null;
	}

	size_t labelIndexFromName(string label) {
		foreach (Variable var; variables)
			if (var.name == label)
				return var.index;
		return -1;
	}

	Variable variableFromName(string name) {
		foreach (Variable var; variables)
			if (var.name == name)
				return var;
		return Variable();
	}

	Entity[] spawned;
	Task[] tasks;
	size_t curTask;
	float curTime = 0;
	float secondTime = 0;
	Variable[] variables;
	ubyte[16][] enemyHashes;
	Enemy[] enemies;
	ResourceManager res;
	World world;
	Game game;
}

unittest {
	Level level = new Level(new Game(), null, null);
	level.variables ~= Variable(VarType.enemy, "a", 4);
	level.variables ~= Variable(VarType.enemy, "b", 3);
	level.variables ~= Variable(VarType.label, "c", 4);
	level.variables ~= Variable(VarType.label, "d", 4);
	level.variables ~= Variable(VarType.flag, "e", true);
	level.variables ~= Variable(VarType.invalid, "f");
	level.variables ~= Variable(VarType.enemy, "g", 4);

	assert(level.evalExpression("a != b"));
	assert(!level.evalExpression("a == b"));
	assert(level.evalExpression("c == d"));
	assert(level.evalExpression("e == e"));
	assert(level.evalExpression("e == true"));
	assert(level.evalExpression("e != false"));
	assert(level.evalExpression("a != c"));
	assert(!level.evalExpression("a == c"));
	assert(level.evalExpression("a != c && a != b && a == g"));
	assert(level.evalExpression("a != c && a == b || a == g"));
}
