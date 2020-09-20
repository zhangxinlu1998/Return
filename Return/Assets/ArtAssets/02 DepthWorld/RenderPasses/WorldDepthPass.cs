using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    /// <summary>
    /// Copy the given color buffer to the given destination color buffer.
    ///
    /// You can use this pass to copy a color buffer to the destination,
    /// so you can use it later in rendering. For example, you can copy
    /// the opaque texture to use it for distortion effects.
    /// </summary>
    internal class WorldDepthPass : ScriptableRenderPass
    {
        public enum RenderTarget
        {
            Color,
            RenderTexture,
        }

        public Material DepthMaterial = null;
        public int DepthShaderPassIndex = 0;
        public FilterMode filterMode { get; set; }

        private RenderTargetIdentifier source { get; set; }
        private RenderTargetHandle destination { get; set; }

        RenderTargetHandle m_TemporaryColorTexture;
        string m_ProfilerTag;


        public WorldDepthPass(RenderPassEvent renderPassEvent, Material DepthMaterial, int DepthShaderPassIndex, string tag)
        {
            this.renderPassEvent = renderPassEvent;
            this.DepthMaterial = DepthMaterial;
            this.DepthShaderPassIndex = DepthShaderPassIndex;
            m_ProfilerTag = tag;
            m_TemporaryColorTexture.Init("_TemporaryColorTexture");
        }

        
        public void Setup(RenderTargetIdentifier source, RenderTargetHandle destination)
        {
            this.source = source;
            this.destination = destination;
        }

        /// <inheritdoc/>
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            int temp = Shader.PropertyToID("temp");
            CommandBuffer cmd = CommandBufferPool.Get("扫描特效");
            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            Camera cam = renderingData.cameraData.camera;
            float height = cam.nearClipPlane * Mathf.Tan(Mathf.Deg2Rad * cam.fieldOfView * 0.5f);
            Vector3 up = cam.transform.up * height;
            Vector3 right = cam.transform.right * height * cam.aspect;
            Vector3 forward = cam.transform.forward * cam.nearClipPlane;
            Vector3 ButtomLeft = forward - right - up;
            float scale = ButtomLeft.magnitude / cam.nearClipPlane;
            ButtomLeft.Normalize();
            ButtomLeft *= scale;
            Vector3 ButtomRight = forward + right - up;
            ButtomRight.Normalize();
            ButtomRight *= scale;
            Vector3 TopRight = forward + right + up;
            TopRight.Normalize();
            TopRight *= scale;
            Vector3 TopLeft = forward - right + up;
            TopLeft.Normalize();
            TopLeft *= scale;
            Matrix4x4 MATRIX = new Matrix4x4();
            MATRIX.SetRow(0, ButtomLeft);
            MATRIX.SetRow(1, ButtomRight);
            MATRIX.SetRow(2, TopRight);
            MATRIX.SetRow(3, TopLeft);
            DepthMaterial.SetMatrix("Matrix", MATRIX);
            cmd.GetTemporaryRT(temp, desc);
            cmd.Blit(source, temp, DepthMaterial);
            cmd.Blit(temp, source);
            context.ExecuteCommandBuffer(cmd);
            cmd.ReleaseTemporaryRT(temp);
            CommandBufferPool.Release(cmd);
        }

        /// <inheritdoc/>
        public override void FrameCleanup(CommandBuffer cmd)
        {
            if (destination == RenderTargetHandle.CameraTarget)
                cmd.ReleaseTemporaryRT(m_TemporaryColorTexture.id);
        }
    }
}
