package
{
	import aerys.minko.render.Viewport;
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.render.effect.skinning.SkinningStyle;
	import aerys.minko.scene.node.camera.ArcBallCamera;
	import aerys.minko.scene.node.group.LoaderGroup;
	import aerys.minko.scene.node.group.StyleGroup;
	import aerys.minko.scene.node.group.TransformGroup;
	import aerys.minko.scene.node.group.collada.ColladaGroup;
	import aerys.minko.scene.node.texture.ColorTexture;
	import aerys.minko.type.animation.SynchronizedAnimation;
	import aerys.minko.type.math.ConstVector4;
	import aerys.minko.type.parser.collada.ColladaParser;
	import aerys.minko.type.skinning.SkinningMethod;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	public class Main extends Sprite
	{
		// OK avec skinning/anims
		[Embed("../assets/astroBoy_walk_Max.DAE", mimeType="application/octet-stream")]
		private static const ASTROBOY_DAE	: Class;
		
		protected var _viewport				: Viewport				= new Viewport(0, 0, true, 2);
		protected var _camera				: ArcBallCamera			= new ArcBallCamera();
		protected var _scene				: StyleGroup			= new StyleGroup(_camera);
		
		protected var _walkAnimation		: SynchronizedAnimation	= null;
		
		protected var _cursor				: Point					= new Point();
		
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
			_scene.style.set(SkinningStyle.METHOD, 	SkinningMethod.DUAL_QUATERNION);
						
			// camera
			_camera.distance = 10;
			_camera.lookAt.y = 3;
			_camera.rotation.y = .4;
			_camera.rotation.x = -.4;
			
			// Load collada content and retrieve main animation.
			var astroBoy	: ColladaGroup		= new LoaderGroup().loadAsset(ASTROBOY_DAE)[0]
												  as ColladaGroup;
			var transformed	: TransformGroup	= new TransformGroup(astroBoy);
			
			transformed.transform.appendRotation(- Math.PI / 2, ConstVector4.X_AXIS) // Z_UP to Y_UP
								 .appendScale(1, 1, -1); // right handed to left handed
			
			_walkAnimation = astroBoy.getAnimationById('mergedAnimations');
			_walkAnimation.playOn(astroBoy);
			_scene.addChild(new ColorTexture(0xffffff)).addChild(transformed);
		}
		
		protected function initEventListeners() : void
		{
			stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
		}
		
		protected function enterFrameHandler(e : Event) : void
		{
			_viewport.render(_scene);
			_walkAnimation.tick();
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