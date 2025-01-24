import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(import.meta.env.VITE_GEMINI_API_KEY);

export async function extractDocumentData(file: File) {
  const model = genAI.getGenerativeModel({ model: "gemini-pro-vision" });
  
  // Convert file to base64
  const arrayBuffer = await file.arrayBuffer();
  const base64 = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)));
  const mimeType = file.type;

  const result = await model.generateContent([
    "Extract and analyze the following document. Return the data in a structured JSON format including fields like name, date, document type, and any other relevant information found.",
    {
      inlineData: {
        mimeType,
        data: base64
      }
    }
  ]);

  const response = await result.response;
  const text = response.text();
  
  try {
    return JSON.parse(text);
  } catch {
    return { rawText: text };
  }
}

export async function validateDocumentAuthenticity(documentData: any) {
  const model = genAI.getGenerativeModel({ model: "gemini-pro" });

  const prompt = `Analyze this document data for authenticity indicators. Consider formatting, consistency, and standard document elements:\n${JSON.stringify(documentData)}`;
  
  const result = await model.generateContent(prompt);
  const response = await result.response;
  const text = response.text();

  return {
    isAuthentic: text.toLowerCase().includes("authentic"),
    confidence: text,
  };
}

export async function compareFaceWithDocument(selfieFile: File, documentFile: File) {
  const model = genAI.getGenerativeModel({ model: "gemini-pro-vision" });
  
  // Convert both files to base64
  const selfieArrayBuffer = await selfieFile.arrayBuffer();
  const documentArrayBuffer = await documentFile.arrayBuffer();
  
  const selfieBase64 = btoa(String.fromCharCode(...new Uint8Array(selfieArrayBuffer)));
  const documentBase64 = btoa(String.fromCharCode(...new Uint8Array(documentArrayBuffer)));

  const result = await model.generateContent([
    "Compare these two face images and determine if they are the same person. Return a JSON response with isMatch (boolean) and confidence (number between 0-1).",
    {
      inlineData: {
        mimeType: selfieFile.type,
        data: selfieBase64
      }
    },
    {
      inlineData: {
        mimeType: documentFile.type,
        data: documentBase64
      }
    }
  ]);

  const response = await result.response;
  const text = response.text();
  
  try {
    const data = JSON.parse(text);
    return {
      isMatch: data.isMatch,
      confidence: data.confidence
    };
  } catch {
    return {
      isMatch: false,
      confidence: 0
    };
  }
}