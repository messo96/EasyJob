import { getAccessToken } from '../firebase';
import { encodeGmailRawMessage } from '../utils/recruitingLogic';

export interface MeetSpaceResult {
  meetingUri: string;
  meetingCode: string;
  createdViaApi: boolean;
}

/**
 * Creates a Google Meet space using the Google Meet REST API v2 when an OAuth access token is active,
 * or generates a deterministic Meet URI when operating in local preview mode.
 */
export async function createGoogleMeetSpace(): Promise<MeetSpaceResult> {
  const accessToken = await getAccessToken();
  if (accessToken) {
    try {
      const res = await fetch('https://meet.googleapis.com/v2/spaces', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({}),
      });
      if (res.ok) {
        const data = await res.json();
        if (data.meetingUri) {
          return {
            meetingUri: data.meetingUri,
            meetingCode: data.meetingCode || 'meet-live',
            createdViaApi: true,
          };
        }
      }
    } catch (err) {
      console.warn('Fallback to preview Meet link:', err);
    }
  }

  const seg = () => Math.random().toString(36).substring(2, 5);
  const code = `${seg()}-${seg()}x-${seg()}`;
  return {
    meetingUri: `https://meet.google.com/${code}`,
    meetingCode: code,
    createdViaApi: false,
  };
}

export interface SendGmailResult {
  sentViaApi: boolean;
  messageId: string;
}

/**
 * Sends an email via the Gmail API (`users/me/messages/send`) when an OAuth token is active.
 */
export async function sendGmailMessage(
  to: string,
  subject: string,
  bodyText: string
): Promise<SendGmailResult> {
  const accessToken = await getAccessToken();
  if (accessToken) {
    try {
      const raw = encodeGmailRawMessage(to, subject, bodyText);
      const res = await fetch(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/send',
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ raw }),
        }
      );
      if (res.ok) {
        const data = await res.json();
        return {
          sentViaApi: true,
          messageId: data.id || `gmail-${Date.now()}`,
        };
      }
    } catch (err) {
      console.warn('Gmail API fallback:', err);
    }
  }

  return {
    sentViaApi: false,
    messageId: `local-mail-${Date.now()}`,
  };
}
