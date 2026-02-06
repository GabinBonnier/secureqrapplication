import {describe, expect, it, vi} from 'vitest'
import {Request, Response, NextFunction} from 'express'
import {authenticateToken} from '../src/auth/auth.middleware'
import jwt from 'jsonwebtoken'

vi.mock('jsonwebtoken')
vi.mock('../src/env', () => ({
    env: {
        JWT_SECRET: 'test-secret'
    }
}))

describe('authenticateToken middleware', () => {
    it('should authenticate valid token', () => {
        const mockDecoded = {userId: 1, email: 'test@example.com'}
        const mockRequest = {headers: {authorization: 'Bearer valid-token'}} as Partial<Request>
        const mockResponse = {
            status: vi.fn().mockReturnThis(),
            json: vi.fn().mockReturnThis()
        } as Partial<Response>
        const nextFunction = vi.fn() as NextFunction

        vi.mocked(jwt.verify).mockReturnValue(mockDecoded as never)

        authenticateToken(mockRequest as Request, mockResponse as Response, nextFunction)

        expect(mockRequest.user).toEqual(mockDecoded)
        expect(nextFunction).toHaveBeenCalled()
        expect(mockResponse.status).not.toHaveBeenCalled()
    })

    it('should return 401 if no token provided', () => {
        const mockRequest = {headers: {}} as Partial<Request>
        const mockResponse = {
            status: vi.fn().mockReturnThis(),
            json: vi.fn().mockReturnThis()
        } as Partial<Response>
        const nextFunction = vi.fn() as NextFunction

        authenticateToken(mockRequest as Request, mockResponse as Response, nextFunction)

        expect(mockResponse.status).toHaveBeenCalledWith(401)
        expect(mockResponse.json).toHaveBeenCalledWith({error: 'Token manquant'})
        expect(nextFunction).not.toHaveBeenCalled()
    })

    it('should return 401 if authorization header is malformed', () => {
        const mockRequest = {headers: {authorization: 'InvalidFormat'}} as Partial<Request>
        const mockResponse = {
            status: vi.fn().mockReturnThis(),
            json: vi.fn().mockReturnThis()
        } as Partial<Response>
        const nextFunction = vi.fn() as NextFunction

        authenticateToken(mockRequest as Request, mockResponse as Response, nextFunction)

        expect(mockResponse.status).toHaveBeenCalledWith(401)
        expect(mockResponse.json).toHaveBeenCalledWith({error: 'Token manquant'})
    })

    it('should return 401 if token is invalid', () => {
        const mockRequest = {headers: {authorization: 'Bearer invalid-token'}} as Partial<Request>
        const mockResponse = {
            status: vi.fn().mockReturnThis(),
            json: vi.fn().mockReturnThis()
        } as Partial<Response>
        const nextFunction = vi.fn() as NextFunction

        vi.mocked(jwt.verify).mockImplementation(() => {
            throw new Error('Invalid token')
        })

        authenticateToken(mockRequest as Request, mockResponse as Response, nextFunction)

        expect(mockResponse.status).toHaveBeenCalledWith(401)
        expect(mockResponse.json).toHaveBeenCalledWith({error: 'Token invalide ou expiré'})
    })

    it('should return 401 if token is expired', () => {
        const mockRequest = {headers: {authorization: 'Bearer expired-token'}} as Partial<Request>
        const mockResponse = {
            status: vi.fn().mockReturnThis(),
            json: vi.fn().mockReturnThis()
        } as Partial<Response>
        const nextFunction = vi.fn() as NextFunction

        vi.mocked(jwt.verify).mockImplementation(() => {
            const error = new Error('Token expired') as any
            error.name = 'TokenExpiredError'
            throw error
        })

        authenticateToken(mockRequest as Request, mockResponse as Response, nextFunction)

        expect(mockResponse.status).toHaveBeenCalledWith(401)
        expect(mockResponse.json).toHaveBeenCalledWith({error: 'Token invalide ou expiré'})
    })
})