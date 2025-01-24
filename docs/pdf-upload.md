# PDF Document Upload Documentation

## Overview
The document upload system allows users to securely upload and manage PDF documents required for their immigration applications. The system supports validation, verification, and secure storage of sensitive documents.

## Features
- Secure PDF file upload
- Document validation and verification
- Automatic data extraction
- Document authenticity checks
- Real-time upload status
- Document type validation
- Size limit enforcement
- Secure storage with Supabase

## Technical Specifications

### Supported File Types
- PDF documents (`.pdf`)
- Maximum file size: 10MB per document

### Security Features
- End-to-end encryption during transfer
- Secure storage in Supabase
- Access control through Row Level Security (RLS)
- Document validation checks
- Authenticity verification

### Upload Process

1. **File Selection**
```typescript
// Example of file selection handling
const handleFileUpload = async (file: File) => {
  if (!file.type === 'application/pdf') {
    throw new Error('Only PDF files are allowed');
  }
  if (file.size > 10 * 1024 * 1024) { // 10MB
    throw new Error('File size must be less than 10MB');
  }
  // Process file...
};
```

2. **Document Validation**
- File type verification
- Size check
- Virus scan
- PDF structure validation
- Page count verification

3. **Data Extraction**
- Automatic text extraction
- Metadata parsing
- Document classification

4. **Storage**
- Files are stored in Supabase storage
- Each file is associated with:
  - Application ID
  - Document type
  - Upload timestamp
  - Verification status

## Implementation Guide

### 1. Document Upload Component
The `DocumentUploader` component handles file uploads:

```typescript
interface Props {
  onUploadComplete: (result: any) => void;
  documentType: string;
}

export default function DocumentUploader({ onUploadComplete, documentType }: Props) {
  // Component implementation...
}
```

### 2. Required Document Types
```typescript
const requiredDocuments = [
  { id: 'passport', label: 'Passport' },
  { id: 'education_certificate', label: 'Education Certificate' },
  { id: 'resume', label: 'Resume/CV' },
  { id: 'police_clearance', label: 'Police Clearance' },
  { id: 'language_test', label: 'Language Test Results' },
  { id: 'work_experience', label: 'Work Experience Letters' }
];
```

### 3. Storage Structure
```plaintext
documents/
  ├── {user_id}/
  │   ├── {application_id}/
  │   │   ├── passport.pdf
  │   │   ├── education_certificate.pdf
  │   │   ├── resume.pdf
  │   │   ├── police_clearance.pdf
  │   │   ├── language_test.pdf
  │   │   └── work_experience.pdf
  │   └── ...
  └── ...
```

### 4. Database Schema
```sql
-- Application documents table
CREATE TABLE application_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES applications(id),
  document_type TEXT NOT NULL,
  file_path TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

## Usage Example

```typescript
// Upload a document
const uploadDocument = async (file: File, documentType: string) => {
  try {
    // 1. Validate file
    if (!validateFile(file)) {
      throw new Error('Invalid file');
    }

    // 2. Generate file path
    const fileExt = file.name.split('.').pop();
    const filePath = `${user.id}/${applicationId}/${documentType}.${fileExt}`;

    // 3. Upload to storage
    const { error: uploadError } = await supabase.storage
      .from('documents')
      .upload(filePath, file);

    if (uploadError) throw uploadError;

    // 4. Create database record
    const { error: docError } = await supabase
      .from('application_documents')
      .insert([{
        application_id: applicationId,
        document_type: documentType,
        file_path: filePath
      }]);

    if (docError) throw docError;

    return { success: true };
  } catch (error) {
    console.error('Error uploading document:', error);
    throw error;
  }
};
```

## Security Considerations

1. **Access Control**
   - Only authenticated users can upload documents
   - Users can only access their own documents
   - Admin users have special access privileges

2. **File Validation**
   - File type verification
   - Size limits
   - Content validation
   - Malware scanning

3. **Storage Security**
   - Encrypted storage
   - Secure file paths
   - Temporary URLs for access

## Error Handling

```typescript
const handleUploadError = (error: any) => {
  switch (error.code) {
    case 'FILE_TOO_LARGE':
      return 'File size exceeds 10MB limit';
    case 'INVALID_FILE_TYPE':
      return 'Only PDF files are allowed';
    case 'STORAGE_ERROR':
      return 'Error storing file. Please try again';
    default:
      return 'An unexpected error occurred';
  }
};
```

## Best Practices

1. **File Naming**
   - Use consistent naming conventions
   - Include document type in filename
   - Avoid special characters

2. **Validation**
   - Always validate files before upload
   - Check file type and size
   - Verify PDF structure
   - Scan for malware

3. **Error Handling**
   - Provide clear error messages
   - Implement retry logic
   - Log upload failures

4. **Performance**
   - Compress files when possible
   - Implement chunked uploads for large files
   - Use loading indicators

## Troubleshooting

Common issues and solutions:

1. **Upload Fails**
   - Check file size
   - Verify file type
   - Check network connection
   - Verify user permissions

2. **File Not Showing**
   - Check storage path
   - Verify database record
   - Check access permissions

3. **Slow Upload**
   - Check file size
   - Verify network speed
   - Consider file compression

## API Reference

### Upload Document
```typescript
async function uploadDocument(
  file: File,
  documentType: string,
  applicationId: string
): Promise<{
  success: boolean;
  filePath: string;
  documentId: string;
}>;
```

### Get Document
```typescript
async function getDocument(
  documentId: string
): Promise<{
  url: string;
  metadata: DocumentMetadata;
}>;
```

### Delete Document
```typescript
async function deleteDocument(
  documentId: string
): Promise<{
  success: boolean;
}>;
```

## Support

For technical support or questions about document uploads, contact:
- Technical Support: support@immigration-portal.com
- Security Issues: security@immigration-portal.com