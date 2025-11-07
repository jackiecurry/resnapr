#!/bin/bash

echo "🔄 Updating reSnapr with live preview features..."

# Update custom-enhancement-dialog.tsx
cat > frontend/src/components/custom-enhancement-dialog.tsx << 'EOF'
"use client";

import { useState, useEffect } from "react";
import { X, Sparkles, RefreshCw } from "lucide-react";
import { Button } from "./ui/button";
import { Slider } from "./ui/slider";

interface CustomEnhancementDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onEnhance: (options: EnhancementOptions) => void;
  analysis: any;
  uploadId: string;
}

export interface EnhancementOptions {
  lighting_method: "auto" | "retinex" | "clahe" | "both";
  sharpness: number;
  denoise: number;
  brightness: number;
  contrast: number;
}

export function CustomEnhancementDialog({
  isOpen,
  onClose,
  onEnhance,
  analysis,
  uploadId,
}: CustomEnhancementDialogProps) {
  const [options, setOptions] = useState<EnhancementOptions>({
    lighting_method: "auto",
    sharpness: analysis?.blur?.is_blurry ? 1.5 : 0,
    denoise: analysis?.noise?.is_noisy ? 1.0 : 0,
    brightness: 0,
    contrast: 1.0,
  });

  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isGeneratingPreview, setIsGeneratingPreview] = useState(false);
  const [previewTimer, setPreviewTimer] = useState<NodeJS.Timeout | null>(null);

  useEffect(() => {
    if (!isOpen) return;

    if (previewTimer) {
      clearTimeout(previewTimer);
    }

    const timer = setTimeout(() => {
      generatePreview();
    }, 800);

    setPreviewTimer(timer);

    return () => {
      if (timer) clearTimeout(timer);
    };
  }, [options, isOpen]);

  const generatePreview = async () => {
    setIsGeneratingPreview(true);
    
    try {
      const response = await fetch(
        \`\${process.env.NEXT_PUBLIC_API_URL}/enhance\`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            upload_id: uploadId,
            mode: "custom",
            options: options,
          }),
        }
      );

      if (response.ok) {
        const timestamp = Date.now();
        setPreviewUrl(
          \`http://localhost:8000/storage/\${uploadId}/enhanced.jpg?t=\${timestamp}\`
        );
      }
    } catch (error) {
      console.error("Preview generation failed:", error);
    } finally {
      setIsGeneratingPreview(false);
    }
  };

  const handleApply = () => {
    onEnhance(options);
    onClose();
  };

  if (!isOpen) return null;

  const originalUrl = \`http://localhost:8000/storage/\${uploadId}/preview.jpg\`;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-5xl w-full max-h-[95vh] overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b sticky top-0 bg-white z-10">
          <div className="flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-blue-500" />
            <h2 className="text-xl font-semibold">Custom Enhancement</h2>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6">
          <div className="grid lg:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="font-semibold">Live Preview</h3>
                {isGeneratingPreview && (
                  <div className="flex items-center gap-2 text-sm text-blue-600">
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    <span>Updating...</span>
                  </div>
                )}
              </div>

              <div className="space-y-3">
                <div>
                  <p className="text-xs font-medium text-gray-500 mb-2">
                    Before
                  </p>
                  <div className="aspect-square bg-gray-100 rounded-lg overflow-hidden">
                    <img
                      src={originalUrl}
                      alt="Original"
                      className="w-full h-full object-contain"
                    />
                  </div>
                </div>

                <div>
                  <p className="text-xs font-medium text-gray-500 mb-2">
                    After Enhancement
                  </p>
                  <div className="aspect-square bg-gray-100 rounded-lg overflow-hidden relative">
                    {previewUrl ? (
                      <img
                        src={previewUrl}
                        alt="Preview"
                        className="w-full h-full object-contain"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-gray-400">
                        <div className="text-center">
                          <RefreshCw className="w-8 h-8 mx-auto mb-2 animate-spin" />
                          <p className="text-sm">Generating preview...</p>
                        </div>
                      </div>
                    )}
                    {isGeneratingPreview && (
                      <div className="absolute inset-0 bg-white bg-opacity-70 flex items-center justify-center">
                        <RefreshCw className="w-8 h-8 text-blue-500 animate-spin" />
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>

            <div className="space-y-6">
              <h3 className="font-semibold">Adjustment Controls</h3>

              <div>
                <label className="text-sm font-medium text-gray-700 mb-2 block">
                  Lighting Correction
                </label>
                <select
                  value={options.lighting_method}
                  onChange={(e) =>
                    setOptions({
                      ...options,
                      lighting_method: e.target.value as any,
                    })
                  }
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="auto">Auto (Recommended)</option>
                  <option value="retinex">Retinex (Brightness Boost)</option>
                  <option value="clahe">CLAHE (Contrast Enhancement)</option>
                  <option value="both">Both (Maximum Correction)</option>
                </select>
              </div>

              <Slider
                label="Unblur"
                value={options.sharpness}
                onChange={(val) => setOptions({ ...options, sharpness: val })}
                min={0}
                max={3}
                step={0.1}
              />
              {analysis?.blur?.is_blurry && (
                <p className="text-sm text-orange-700 -mt-4">
                  ⚠️ Blur detected - unblur recommended
                </p>
              )}

              <Slider
                label="Noise Reduction"
                value={options.denoise}
                onChange={(val) => setOptions({ ...options, denoise: val })}
                min={0}
                max={2}
                step={0.1}
              />
              {analysis?.noise?.is_noisy && (
                <p className="text-sm text-purple-700 -mt-4">
                  ⚠️ Noise detected - reduction recommended
                </p>
              )}

              <Slider
                label="Brightness"
                value={options.brightness}
                onChange={(val) => setOptions({ ...options, brightness: val })}
                min={-100}
                max={100}
                step={5}
              />

              <Slider
                label="Contrast"
                value={options.contrast}
                onChange={(val) => setOptions({ ...options, contrast: val })}
                min={0.5}
                max={2.0}
                step={0.1}
              />
            </div>
          </div>
        </div>

        <div className="p-6 border-t bg-gray-50 flex gap-3 sticky bottom-0">
          <Button onClick={onClose} variant="outline" className="flex-1">
            Cancel
          </Button>
          <Button onClick={handleApply} className="flex-1">
            <Sparkles className="w-4 h-4 mr-2" />
            Apply & Save
          </Button>
        </div>
      </div>
    </div>
  );
}
EOF

# Update upload-section.tsx
cat > frontend/src/components/upload-section.tsx << 'EOF2'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useDropzone } from "react-dropzone";
import { Upload, Sparkles, AlertCircle } from "lucide-react";
import { Button } from "./ui/button";
import { PhotoEnhancementAPI } from "@/lib/api";
import {
  CustomEnhancementDialog,
  EnhancementOptions,
} from "./custom-enhancement-dialog";

export function UploadSection() {
  const router = useRouter();
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [isEnhancing, setIsEnhancing] = useState(false);
  const [analysis, setAnalysis] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);
  const [uploadId, setUploadId] = useState<string | null>(null);
  const [showCustomDialog, setShowCustomDialog] = useState(false);

  const onDrop = async (acceptedFiles: File[]) => {
    const file = acceptedFiles[0];
    if (!file) return;

    setIsAnalyzing(true);
    setError(null);
    setAnalysis(null);

    try {
      const result = await PhotoEnhancementAPI.uploadPhoto(file);
      setAnalysis(result.analysis);
      setUploadId(result.upload_id);
    } catch (err: any) {
      setError(err.message || "Failed to analyze photo");
    } finally {
      setIsAnalyzing(false);
    }
  };

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { "image/*": [".jpeg", ".jpg", ".png", ".webp"] },
    maxFiles: 1,
    disabled: isAnalyzing,
  });

  const handleAutoEnhance = async () => {
    if (!uploadId) return;

    setIsEnhancing(true);
    try {
      await PhotoEnhancementAPI.enhancePhoto(uploadId, "auto");
      router.push(\`/results/\${uploadId}\`);
    } catch (err: any) {
      setError(err.message || "Enhancement failed");
      setIsEnhancing(false);
    }
  };

  const handleCustomEnhance = async (options: EnhancementOptions) => {
    if (!uploadId) return;

    setIsEnhancing(true);
    try {
      const result = await fetch(
        \`\${process.env.NEXT_PUBLIC_API_URL}/enhance\`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            upload_id: uploadId,
            mode: "custom",
            options,
          }),
        }
      );

      if (!result.ok) throw new Error("Enhancement failed");

      router.push(\`/results/\${uploadId}\`);
    } catch (err: any) {
      setError(err.message || "Enhancement failed");
      setIsEnhancing(false);
    }
  };

  return (
    <>
      <div className="w-full max-w-2xl mx-auto space-y-6">
        <div
          {...getRootProps()}
          className={\`
          border-2 border-dashed rounded-lg p-12 text-center cursor-pointer
          transition-colors duration-200
          \${
            isDragActive
              ? "border-blue-500 bg-blue-50"
              : "border-gray-300 hover:border-gray-400"
          }
          \${isAnalyzing ? "opacity-50 cursor-not-allowed" : ""}
        \`}
        >
          <input {...getInputProps()} />
          <Upload className="w-12 h-12 mx-auto mb-4 text-gray-400" />
          {isAnalyzing ? (
            <div>
              <p className="text-lg font-medium mb-2">Analyzing photo...</p>
              <div className="flex justify-center">
                <Sparkles className="w-5 h-5 animate-pulse text-blue-500" />
              </div>
            </div>
          ) : (
            <div>
              <p className="text-lg font-medium mb-2">
                Drop your photo here or click to browse
              </p>
              <p className="text-sm text-gray-500">
                JPEG, PNG, or WebP • Max 10MB
              </p>
            </div>
          )}
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-red-600 mt-0.5" />
            <div>
              <p className="font-medium text-red-900">Error</p>
              <p className="text-sm text-red-700">{error}</p>
            </div>
          </div>
        )}

        {analysis && !isEnhancing && (
          <div className="bg-white border border-gray-200 rounded-lg p-6 space-y-4">
            <div className="flex items-center gap-2">
              <Sparkles className="w-5 h-5 text-blue-500" />
              <h3 className="font-semibold text-lg">AI Analysis Complete</h3>
            </div>

            <p className="text-gray-700">{analysis.claude?.description}</p>

            {(analysis.claude?.issues?.length > 0 ||
              analysis.blur?.is_blurry ||
              analysis.noise?.is_noisy) && (
              <div>
                <p className="text-sm font-medium text-gray-600 mb-2">
                  Issues Detected:
                </p>
                <div className="flex flex-wrap gap-2">
                  {analysis.claude?.issues?.map((issue: string) => (
                    <span
                      key={issue}
                      className="px-3 py-1 bg-yellow-100 text-yellow-800 rounded-full text-sm"
                    >
                      {issue.replace(/_/g, " ")}
                    </span>
                  ))}
                  {analysis.blur?.is_blurry && (
                    <span className="px-3 py-1 bg-orange-100 text-orange-800 rounded-full text-sm">
                      {analysis.blur.blur_level.replace(/_/g, " ")}
                    </span>
                  )}
                  {analysis.noise?.is_noisy && (
                    <span className="px-3 py-1 bg-purple-100 text-purple-800 rounded-full text-sm">
                      {analysis.noise.noise_level.replace(/_/g, " ")}
                    </span>
                  )}
                </div>
              </div>
            )}

            <div className="grid grid-cols-2 gap-4 pt-3 border-t border-gray-200">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-gray-600">
                  Quality Score
                </span>
                <span className="text-lg font-bold text-blue-600">
                  {analysis.claude?.quality_score}/10
                </span>
              </div>

              {analysis.lighting?.brightness && (
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-gray-600">
                    Brightness
                  </span>
                  <span className="text-sm text-gray-700">
                    {Math.round(analysis.lighting.brightness)}/255
                  </span>
                </div>
              )}

              {analysis.blur?.blur_score && (
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-gray-600">
                    Sharpness
                  </span>
                  <span className="text-sm text-gray-700">
                    {Math.round(analysis.blur.blur_score)}
                  </span>
                </div>
              )}

              {analysis.noise?.noise_score && (
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-gray-600">
                    Noise Level
                  </span>
                  <span className="text-sm text-gray-700">
                    {Math.round(analysis.noise.noise_score)}
                  </span>
                </div>
              )}
            </div>

            <div className="flex gap-3 pt-4">
              <Button
                onClick={handleAutoEnhance}
                className="flex-1"
                size="lg"
              >
                <Sparkles className="w-4 h-4 mr-2" />
                Fix My Shot
              </Button>
              <Button
                onClick={() => setShowCustomDialog(true)}
                variant="outline"
                className="flex-1"
                size="lg"
              >
                Custom Mode
              </Button>
            </div>
          </div>
        )}

        {isEnhancing && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 text-center">
            <Sparkles className="w-8 h-8 mx-auto mb-3 animate-pulse text-blue-500" />
            <p className="text-lg font-medium text-blue-900">
              Enhancing your photo...
            </p>
            <p className="text-sm text-blue-700 mt-1">
              Applying magic touches ✨
            </p>
          </div>
        )}
      </div>

      {uploadId && (
        <CustomEnhancementDialog
          isOpen={showCustomDialog}
          onClose={() => setShowCustomDialog(false)}
          onEnhance={handleCustomEnhance}
          analysis={analysis}
          uploadId={uploadId}
        />
      )}
    </>
  );
}
EOF2

echo "✅ Files updated successfully!"
echo ""
echo "Frontend should auto-reload. Refresh your browser and try Custom Mode!"
