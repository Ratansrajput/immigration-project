import * as faceapi from '@microsoft/face-api';

export async function compareFaceWithDocument(selfieFile: File, documentFile: File) {
  await faceapi.nets.faceRecognitionNet.loadFromUri('/models');
  await faceapi.nets.faceLandmark68Net.loadFromUri('/models');
  await faceapi.nets.ssdMobilenetv1.loadFromUri('/models');

  const selfieImage = await faceapi.bufferToImage(selfieFile);
  const documentImage = await faceapi.bufferToImage(documentFile);

  const selfieFaceDescriptor = await getFaceDescriptor(selfieImage);
  const documentFaceDescriptor = await getFaceDescriptor(documentImage);

  if (!selfieFaceDescriptor || !documentFaceDescriptor) {
    throw new Error('Could not detect face in one or both images');
  }

  const distance = faceapi.euclideanDistance(selfieFaceDescriptor, documentFaceDescriptor);
  const threshold = 0.6;
  
  return {
    isMatch: distance < threshold,
    confidence: 1 - distance,
  };
}

async function getFaceDescriptor(image: HTMLImageElement) {
  const detections = await faceapi
    .detectSingleFace(image)
    .withFaceLandmarks()
    .withFaceDescriptor();

  return detections?.descriptor;
}