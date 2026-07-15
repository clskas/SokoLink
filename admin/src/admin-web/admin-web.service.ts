import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios, { AxiosInstance } from 'axios';

@Injectable()
export class AdminWebService {
  private readonly http: AxiosInstance;

  constructor(config: ConfigService) {
    this.http = axios.create({
      baseURL: config.get('API_BASE_URL', 'http://127.0.0.1:3100/v1'),
      timeout: 15000,
    });
  }

  async login(email: string, password: string) {
    const { data } = await this.http.post('/auth/login', { email, password });
    if (data.user?.role !== 'ADMIN') {
      throw new Error('Compte non admin');
    }
    return data as { accessToken: string; user: { email: string; fullName?: string } };
  }

  async stats(token: string) {
    const { data } = await this.http.get('/admin/stats', {
      headers: { Authorization: `Bearer ${token}` },
    });
    return data;
  }

  async companies(token: string) {
    const { data } = await this.http.get('/admin/companies', {
      headers: { Authorization: `Bearer ${token}` },
    });
    return data;
  }

  async documents(token: string) {
    const { data } = await this.http.get('/admin/documents', {
      headers: { Authorization: `Bearer ${token}` },
    });
    return data;
  }

  async reviewDoc(token: string, id: string, status: string, rejectReason?: string) {
    const { data } = await this.http.patch(
      `/admin/documents/${id}`,
      { status, rejectReason },
      { headers: { Authorization: `Bearer ${token}` } },
    );
    return data;
  }

  async proRequests(token: string) {
    const { data } = await this.http.get('/admin/pro-requests', {
      headers: { Authorization: `Bearer ${token}` },
    });
    return data;
  }

  async activatePro(token: string, id: string) {
    const { data } = await this.http.post(
      `/admin/pro-requests/${id}/activate`,
      {},
      { headers: { Authorization: `Bearer ${token}` } },
    );
    return data;
  }

  async suspend(token: string, id: string, suspended: boolean) {
    const { data } = await this.http.patch(
      `/admin/companies/${id}/suspend`,
      { suspended },
      { headers: { Authorization: `Bearer ${token}` } },
    );
    return data;
  }

  async setRoles(token: string, id: string, roles: string[]) {
    const { data } = await this.http.patch(
      `/admin/companies/${id}/roles`,
      { roles },
      { headers: { Authorization: `Bearer ${token}` } },
    );
    return data;
  }

  async revenue(token: string) {
    const { data } = await this.http.get('/admin/revenue', {
      headers: { Authorization: `Bearer ${token}` },
    });
    return data;
  }

  async payments(token: string, status?: string) {
    const { data } = await this.http.get('/admin/payments', {
      params: status ? { status } : undefined,
      headers: { Authorization: `Bearer ${token}` },
    });
    return data;
  }

  async confirmPayment(token: string, id: string) {
    const { data } = await this.http.post(
      `/admin/payments/${id}/confirm`,
      {},
      { headers: { Authorization: `Bearer ${token}` } },
    );
    return data;
  }

  async rejectPayment(token: string, id: string) {
    const { data } = await this.http.post(
      `/admin/payments/${id}/reject`,
      {},
      { headers: { Authorization: `Bearer ${token}` } },
    );
    return data;
  }

  async recordPayment(token: string, body: Record<string, unknown>) {
    const { data } = await this.http.post('/admin/payments', body, {
      headers: { Authorization: `Bearer ${token}` },
    });
    return data;
  }

  async updateSubscription(
    token: string,
    id: string,
    body: Record<string, unknown>,
  ) {
    const { data } = await this.http.post(
      `/admin/companies/${id}/subscription`,
      body,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    return data;
  }
}
