import {describe, expect, it, vi} from 'vitest'
import request from 'supertest'
import {prismaMock} from './vitest.setup'
import {app} from '../src/index'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'

vi.mock('bcryptjs')
vi.mock('jsonwebtoken')

describe('POST /api/auth/sign-up', () => {
    it('should create a new user and return token', async () => {
        const mockUser = {
            id: 1,
            email: 'test@example.com',
            username: 'testuser',
            password: 'hashedpassword',
            createdAt: new Date(),
            updatedAt: new Date()
        }

        vi.mocked(bcrypt.hash).mockResolvedValue('hashedpassword' as never)
        vi.mocked(jwt.sign).mockReturnValue('mock-token' as never)
        prismaMock.user.findUnique.mockResolvedValue(null)
        prismaMock.user.create.mockResolvedValue(mockUser)

        const response = await request(app)
            .post('/api/auth/sign-up')
            .send({
                email: 'test@example.com',
                username: 'testuser',
                password: 'password123'
            })

        expect(response.status).toBe(201)
        expect(response.body).toHaveProperty('token', 'mock-token')
        expect(response.body.user).toHaveProperty('id', 1)
        expect(response.body.user).toHaveProperty('username', 'testuser')
    })

    it('should return 400 if data is missing', async () => {
        const response = await request(app)
            .post('/api/auth/sign-up')
            .send({email: 'test@example.com'})

        expect(response.status).toBe(400)
        expect(response.body).toHaveProperty('error', 'Données manquantes')
    })

    it('should return 409 if email already exists', async () => {
        const existingUser = {
            id: 1,
            email: 'test@example.com',
            username: 'existing',
            password: 'hashedpassword',
            createdAt: new Date(),
            updatedAt: new Date()
        }

        prismaMock.user.findUnique.mockResolvedValue(existingUser)

        const response = await request(app)
            .post('/api/auth/sign-up')
            .send({
                email: 'test@example.com',
                username: 'testuser',
                password: 'password123'
            })

        expect(response.status).toBe(409)
        expect(response.body).toHaveProperty('error', 'Email déjà utilisé')
    })

    it('should return 500 on server error', async () => {
        prismaMock.user.findUnique.mockRejectedValue(new Error('Database error'))

        const response = await request(app)
            .post('/api/auth/sign-up')
            .send({
                email: 'test@example.com',
                username: 'testuser',
                password: 'password123'
            })

        expect(response.status).toBe(500)
        expect(response.body).toHaveProperty('error', 'Erreur serveur')
    })
})

describe('POST /api/auth/sign-in', () => {
    it('should authenticate user and return token', async () => {
        const mockUser = {
            id: 1,
            email: 'test@example.com',
            username: 'testuser',
            password: 'hashedpassword',
            createdAt: new Date(),
            updatedAt: new Date()
        }

        vi.mocked(bcrypt.compare).mockResolvedValue(true as never)
        vi.mocked(jwt.sign).mockReturnValue('mock-token' as never)
        prismaMock.user.findUnique.mockResolvedValue(mockUser)

        const response = await request(app)
            .post('/api/auth/sign-in')
            .send({
                email: 'test@example.com',
                password: 'password123'
            })

        expect(response.status).toBe(200)
        expect(response.body).toHaveProperty('token', 'mock-token')
        expect(response.body.user).toHaveProperty('username', 'testuser')
    })

    it('should return 400 if data is missing', async () => {
        const response = await request(app)
            .post('/api/auth/sign-in')
            .send({email: 'test@example.com'})

        expect(response.status).toBe(400)
        expect(response.body).toHaveProperty('error', 'Données manquantes')
    })

    it('should return 401 if user not found', async () => {
        prismaMock.user.findUnique.mockResolvedValue(null)

        const response = await request(app)
            .post('/api/auth/sign-in')
            .send({
                email: 'test@example.com',
                password: 'password123'
            })

        expect(response.status).toBe(401)
        expect(response.body).toHaveProperty('error', 'Email ou mot de passe incorrect')
    })

    it('should return 401 if password is invalid', async () => {
        const mockUser = {
            id: 1,
            email: 'test@example.com',
            username: 'testuser',
            password: 'hashedpassword',
            createdAt: new Date(),
            updatedAt: new Date()
        }

        vi.mocked(bcrypt.compare).mockResolvedValue(false as never)
        prismaMock.user.findUnique.mockResolvedValue(mockUser)

        const response = await request(app)
            .post('/api/auth/sign-in')
            .send({
                email: 'test@example.com',
                password: 'wrongpassword'
            })

        expect(response.status).toBe(401)
        expect(response.body).toHaveProperty('error', 'Email ou mot de passe incorrect')
    })

    it('should return 500 on server error', async () => {
        prismaMock.user.findUnique.mockRejectedValue(new Error('Database error'))

        const response = await request(app)
            .post('/api/auth/sign-in')
            .send({
                email: 'test@example.com',
                password: 'password123'
            })

        expect(response.status).toBe(500)
        expect(response.body).toHaveProperty('error', 'Erreur serveur')
    })
})