package
{
	import aerys.minko.Minko;
	import aerys.minko.render.Viewport;
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.render.effect.skinning.SkinningStyle;
	import aerys.minko.scene.node.camera.ArcBallCamera;
	import aerys.minko.scene.node.group.Group;
	import aerys.minko.scene.node.group.LoaderGroup;
	import aerys.minko.scene.node.group.StyleGroup;
	import aerys.minko.scene.node.group.TransformGroup;
	import aerys.minko.scene.node.group.collada.ColladaGroup;
	import aerys.minko.scene.node.texture.ColorTexture;
	import aerys.minko.type.animation.AbstractAnimation;
	import aerys.minko.type.animation.ManualAnimation;
	import aerys.minko.type.animation.SynchronizedAnimation;
	import aerys.minko.type.log.DebugLevel;
	import aerys.minko.type.math.ConstVector4;
	import aerys.minko.type.parser.collada.ColladaParser;
	import aerys.minko.type.skinning.SkinningMethod;
	
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
		
		protected var _viewport				: Viewport		= new Viewport(0, 0, true, 2);
		protected var _camera				: ArcBallCamera	= new ArcBallCamera();
		protected var _scene				: StyleGroup	= new StyleGroup(_camera);
		
		protected var _walkAnimation		: SynchronizedAnimation	= null;
		
		protected var _keyDowns				: Array			= new Array();
		protected var _cursor				: Point			= new Point();
		
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
			stage.addChild(_viewport);
			
			initScene();
			initEventListeners();
		}
		
		protected function initScene() : void
		{
			_scene.style.set(SkinningStyle.METHOD, 		SkinningMethod.DUAL_QUATERNION);
			
			// camera
			_camera.distance = 30;
			
			// Load collada content and retrieve main animation.
			var astroBoy	: ColladaGroup		= LoaderGroup.loadAsset(ASTROBOY_DAE)[0] as ColladaGroup;
			var transformed	: TransformGroup	= new TransformGroup(astroBoy);
			
			transformed.transform.appendRotation(- Math.PI / 2, ConstVector4.X_AXIS) // Z_UP to Y_UP
								 .appendScale(1, 1, -1); // right handed to left handed
			
			_walkAnimation = astroBoy.getAnimationById('mergedAnimations');
			_walkAnimation.playOn(astroBoy);
			_scene.addChild(new ColorTexture(0xffffff)).addChild(transformed);
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
			_walkAnimation.tick();
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