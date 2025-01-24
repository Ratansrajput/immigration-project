import React, { useState } from 'react';
import { Upload, Check, AlertTriangle } from 'lucide-react';
import { extractDocumentData, validateDocumentAuthenticity, compareFaceWithDocument } from '../services/documentAI';

interface Props {
  onUploadComplete: (result: any) => void;
  documentType: string;
}

export default function DocumentUploader({ onUploadComplete, documentType }: Props) {
  const [loading, setLoading] = useState(false);
  const [validationResult, setValidationResult] = useState<any>(null);

  const handleFileUpload = async (file: File) => {
    setLoading(true);
    try {
      // Extract data from document
      const extractedData = await extractDocumentData(file);
      
      // Validate document authenticity
      const authenticity = await validateDocumentAuthenticity(extractedData);
      
      // If this is an ID document, request selfie for face comparison
      let faceMatch = null;
      if (documentType === 'identification') {
        const selfieInput = document.createElement('input');
        selfieInput.type = 'file';
        selfieInput.accept = 'image/*';
        selfieInput.onchange = async (e) => {
          const selfieFile = (e.target as HTMLInputElement).files?.[0];
          if (selfieFile) {
            faceMatch = await compareFaceWithDocument(selfieFile, file);
          }
        };
        selfieInput.click();
      }

      const result = {
        extractedData,
        authenticity,
        faceMatch,
        file,
      };

      setValidationResult(result);
      onUploadComplete(result);
    } catch (error) {
      console.error('Error processing document:', error);
      alert('Error processing document. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-4">
      <label className="block p-6 border-2 border-dashed border-gray-300 rounded-lg hover:border-indigo-500 transition-colors cursor-pointer">
        <div className="flex flex-col items-center">
          <Upload className="h-8 w-8 text-gray-400 mb-2" />
          <span className="text-sm font-medium text-gray-700">
            {loading ? 'Processing...' : 'Upload Document'}
          </span>
          <input
            type="file"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) handleFileUpload(file);
            }}
            accept=".pdf,.jpg,.jpeg,.png"
          />
        </div>
      </label>

      {validationResult && (
        <div className="p-4 rounded-lg bg-gray-50">
          <div className="flex items-center space-x-2">
            {validationResult.authenticity.isAuthentic ? (
              <Check className="h-5 w-5 text-green-500" />
            ) : (
              <AlertTriangle className="h-5 w-5 text-yellow-500" />
            )}
            <span className="text-sm font-medium">
              Document Validation Result
            </span>
          </div>
          <p className="mt-2 text-sm text-gray-600">
            {validationResult.authenticity.confidence}
          </p>
          {validationResult.faceMatch && (
            <div className="mt-2">
              <div className="flex items-center space-x-2">
                {validationResult.faceMatch.isMatch ? (
                  <Check className="h-5 w-5 text-green-500" />
                ) : (
                  <AlertTriangle className="h-5 w-5 text-yellow-500" />
                )}
                <span className="text-sm font-medium">
                  Face Match Result: {Math.round(validationResult.faceMatch.confidence * 100)}%
                </span>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}