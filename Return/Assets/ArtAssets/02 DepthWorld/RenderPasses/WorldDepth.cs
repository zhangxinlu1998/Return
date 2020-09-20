using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class WorldDepth : ScriptableRendererFeature
    {
        [System.Serializable]
        public class WorldDepthSettings
        {
            public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;

            public Material DepthMaterial = null;
            public int DepthShaderPassIndex = -1;
            public Target destination = Target.Color;
            public string textureId = "_PassTexture";
        }

        public enum Target
        {
            Color,
            Texture
        }

        public WorldDepthSettings settings = new WorldDepthSettings();
        RenderTargetHandle m_RenderTextureHandle;

        WorldDepthPass worlddepthPass;

        public override void Create()
        {
            var passIndex = settings.DepthMaterial != null ? settings.DepthMaterial.passCount - 1 : 1;
            settings.DepthShaderPassIndex = Mathf.Clamp(settings.DepthShaderPassIndex, -1, passIndex);
            worlddepthPass = new WorldDepthPass(settings.Event, settings.DepthMaterial, settings.DepthShaderPassIndex, name);
            m_RenderTextureHandle.Init(settings.textureId);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var src = renderer.cameraColorTarget;
            var dest = (settings.destination == Target.Color) ? RenderTargetHandle.CameraTarget : m_RenderTextureHandle;

            if (settings.DepthMaterial == null)
            {
                Debug.LogWarningFormat("Missing Depth Material. {0} blit pass will not execute. Check for missing reference in the assigned renderer.", GetType().Name);
                return;
            }

            worlddepthPass.Setup(src, dest);
            renderer.EnqueuePass(worlddepthPass);
        }
    }
}

