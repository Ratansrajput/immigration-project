// Using Supabase Edge Functions for email sending
import { supabase } from '../lib/supabase';

export async function sendApplicationStatusEmail(to: string, status: string, programName: string) {
  try {
    const { data, error } = await supabase.functions.invoke('send-email', {
      body: {
        to,
        subject: `Immigration Application Status Update - ${programName}`,
        content: {
          text: `Your application for ${programName} has been ${status}.`,
          html: `
            <h1>Application Status Update</h1>
            <p>Your application for <strong>${programName}</strong> has been <strong>${status}</strong>.</p>
          `
        }
      }
    });

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error sending email:', error);
    throw error;
  }
}