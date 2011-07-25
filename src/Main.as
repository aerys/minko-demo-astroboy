package
{
	import aerys.minko.Minko;
	import aerys.minko.render.Viewport;
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.render.effect.light.LightingStyle;
	import aerys.minko.render.effect.lighting.LightingEffect;
	import aerys.minko.render.effect.skinning.SkinningStyle;
	import aerys.minko.render.renderer.state.TriangleCulling;
	import aerys.minko.scene.node.camera.ArcBallCamera;
	import aerys.minko.scene.node.group.Group;
	import aerys.minko.scene.node.group.LoaderGroup;
	import aerys.minko.scene.node.group.StyleGroup;
	import aerys.minko.scene.node.group.TransformGroup;
	import aerys.minko.scene.node.group.collada.ColladaGroup;
	import aerys.minko.scene.node.light.AmbientLight;
	import aerys.minko.scene.node.light.DirectionalLight;
	import aerys.minko.type.animation.Animation;
	import aerys.minko.type.log.DebugLevel;
	import aerys.minko.type.math.ConstVector4;
	import aerys.minko.type.math.Vector4;
	import aerys.minko.type.parser.IParser3D;
	import aerys.minko.type.parser.collada.ColladaParser;
	import aerys.minko.type.parser.collada.Document;
	import aerys.minko.type.skinning.SkinningMethod;
	import aerys.monitor.Monitor;
	
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	public class Main extends Sprite
	{
		// OK avec skinning/anims
		[Embed("../assets/astroBoy_walk_Max.DAE", mimeType="application/octet-stream")]
		private static const ASTROBOY_DAE	: Class;
		
		protected var _cursor				: Point;
		
		protected var _viewport				: Viewport;
		protected var _scene				: Group;
		protected var _camera				: ArcBallCamera;
		
		protected var _keyDowns				: Array;
		protected var _walkAnimation		: Animation;
		
		public function Main()
		{
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		protected function init(e : Event = null) : void
		{
			// register collada parser
			LoaderGroup.registerParser('dae', new ColladaParser());
			
			removeEventListener(Event.ADDED_TO_STAGE, init);
			_cursor		= new Point();
			_viewport	= new Viewport(0, 0, true, 2);
			stage.addChild(_viewport);
			
			Minko.debugLevel = DebugLevel.DISABLED;
			
			initializeMonitor();
			initScene();
			initEventListeners();
		}
		
		private function initializeMonitor() : void
		{
			var m : Monitor = Monitor.monitor;
			
			addChild(m);
			m.visible = true;
			
			m.watch(_viewport, ["renderingTime", "drawingTime", "numTriangles", "sceneSize"]);
		}
		
		protected function initScene() : void
		{
			_scene = new StyleGroup();
			_scene.style.set(BasicStyle.DIFFUSE_COLOR, 0xffffffff)
						.set(LightingStyle.LIGHT_ENABLED, true)
						.set(BasicStyle.TRIANGLE_CULLING, TriangleCulling.DISABLED)
						.set(SkinningStyle.METHOD, SkinningMethod.DUAL_QUATERNION);
			
			var light : DirectionalLight = new DirectionalLight(0xffffff, 0.6, 0, 0, new Vector4(0, 1, 1));
			_scene.addChild(new AmbientLight());
			_scene.addChild(light);
			
			// Camera
			_camera = new ArcBallCamera();
			_camera.distance = 30;
			_camera.up.set(0, 1, 0);
			_scene.addChild(_camera);
			
			// Load collada content and retrieve main animation.
			var astroBoy	: ColladaGroup		= LoaderGroup.loadAsset(ASTROBOY_DAE)[0] as ColladaGroup;
			var transformed	: TransformGroup	= new TransformGroup(astroBoy);
			
			transformed.transform.appendRotation(- Math.PI / 2, ConstVector4.X_AXIS) // Z_UP to Y_UP
								 .appendScale(1, 1, -1); // right handed to left handed
			
			_walkAnimation = astroBoy.getAnimationById('mergedAnimations');
			_walkAnimation.playOn(astroBoy);
			_scene.addChild(transformed);
		}
		
		protected function initEventListeners() : void
		{
			_keyDowns = [];
			
			stage.addEventListener(Event.ENTER_FRAME,		enterFrameHandler);
			stage.addEventListener(KeyboardEvent.KEY_DOWN,	keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP,	keyUpHandler);
			
			stage.addEventListener(MouseEvent.MOUSE_WHEEL,	mouseWheelHandler);
			stage.addEventListener(MouseEvent.MOUSE_MOVE,	mouseMoveHandler);
		}
		
		protected function enterFrameHandler(e : Event) : void
		{
			_viewport.render(_scene);
			
			if (_keyDowns[Keyboard.UP])
			{
				_walkAnimation.step();
			}
			
			if (_keyDowns[Keyboard.DOWN])
			{
				_walkAnimation.stepReverse();
			}
		}
		
		private function keyDownHandler(e : KeyboardEvent) : void
		{
			switch (e.keyCode)
			{
				case Keyboard.F :
					stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
					break ;
				
				case Keyboard.UP:
				case Keyboard.DOWN:
				case Keyboard.LEFT:
				case Keyboard.RIGHT:
					_keyDowns[e.keyCode] = true;
					break;
			}
		}
		
		private function keyUpHandler(e : KeyboardEvent) : void
		{
			switch (e.keyCode)
			{
				case Keyboard.UP:
				case Keyboard.DOWN:
				case Keyboard.LEFT:
				case Keyboard.RIGHT:
					_keyDowns[e.keyCode] = false;
					break;
			}
		}
		
		private function mouseWheelHandler(event : MouseEvent) : void
		{
			_camera.distance -= .1 * event.delta;
			
			if (_camera.distance > _camera.farClipping)
				_camera.distance = _camera.farClipping;
			
			else if (_camera.distance < 0.)
				_camera.distance = 0.;
		}
		
		private function mouseMoveHandler(event : MouseEvent) : void
		{
			if (event.buttonDown)
			{
				_camera.rotation.y -= (event.stageX - _cursor.x) * .01;
				_camera.rotation.x -= (event.stageY - _cursor.y) * .01;
			}
			
			_cursor.x = event.stageX;
			_cursor.y = event.stageY;
		}
	}
}