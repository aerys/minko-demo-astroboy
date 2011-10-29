package
{
	import aerys.minko.render.Viewport;
	import aerys.minko.render.effect.animation.AnimationStyle;
	import aerys.minko.scene.node.IScene;
	import aerys.minko.scene.node.camera.ArcBallCamera;
	import aerys.minko.scene.node.group.Group;
	import aerys.minko.scene.node.group.LoaderGroup;
	import aerys.minko.scene.node.group.StyleGroup;
	import aerys.minko.scene.node.group.TransformGroup;
	import aerys.minko.type.animation.AnimationMethod;
	import aerys.minko.type.math.ConstVector4;
	import aerys.minko.type.parser.ParserOptions;
	import aerys.minko.type.parser.collada.ColladaParser;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	public class Main extends Sprite
	{
		[Embed("../assets/astroboy.dae", mimeType="application/octet-stream")]
		private static const ASTROBOY_DAE		: Class;
		[Embed("../assets/astroboy.jpg")]
		private static const ASTROBOY_DIFFUSE	: Class;
		
		protected var _viewport	: Viewport		= new Viewport(2);
		protected var _camera	: ArcBallCamera	= new ArcBallCamera();
		protected var _scene	: StyleGroup	= new StyleGroup(_camera);
		
		protected var _cursor	: Point			= new Point();
		
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
			LoaderGroup.registerParser('dae', ColladaParser);
			
			removeEventListener(Event.ADDED_TO_STAGE, init);
			stage.frameRate = 30.;
			stage.addChild(_viewport);
			
			initScene();
			initEventListeners();
		}
		
		protected function initScene() : void
		{
			_scene.style.set(AnimationStyle.METHOD, 	AnimationMethod.DUAL_QUATERNION_SKINNING);
			
			// camera
			_camera.distance = 10;
			_camera.lookAt.y = 3;
			_camera.rotation.y = .4;
			_camera.rotation.x = -.4;
			
			var options	: ParserOptions	= new ParserOptions();
			
			options.loadTextures = true;
			options.loadFunction = function(request : URLRequest, options : ParserOptions) : IScene
			{
				return LoaderGroup.loadClass(ASTROBOY_DIFFUSE)[0];
			};
			
			// load collada content and retrieve main animation
			var astroBoy	: Group				= LoaderGroup.loadClass(ASTROBOY_DAE, options);
			var transformed	: TransformGroup	= new TransformGroup(astroBoy);
		
			transformed.transform
				.appendRotation(- Math.PI / 2, ConstVector4.X_AXIS)	// Z_UP to Y_UP
				.appendScale(1, 1, -1);								// right handed to left handed
			
			_scene.addChild(transformed);
		}
	
		protected function initEventListeners() : void
		{
			stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
		}
		
		protected function enterFrameHandler(e : Event) : void
		{
			_viewport.render(_scene);
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
