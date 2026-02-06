import {describe, expect, it} from 'vitest'
import request from 'supertest'
import {prismaMock} from './vitest.setup'
import {app} from '../src/index'
import {PokemonType} from '../src/generated/prisma/enums'

describe('GET /api/cards', () => {
    it('should return all cards ordered by pokedex number', async () => {
        const mockCards = [
            {
                id: 1,
                name: 'Bulbasaur',
                hp: 45,
                attack: 49,
                type: PokemonType.Grass,
                pokedexNumber: 1,
                imgUrl: 'https://example.com/1.png',
                createdAt: new Date(),
                updatedAt: new Date()
            },
            {
                id: 4,
                name: 'Charmander',
                hp: 39,
                attack: 52,
                type: PokemonType.Fire,
                pokedexNumber: 4,
                imgUrl: 'https://example.com/4.png',
                createdAt: new Date(),
                updatedAt: new Date()
            }
        ]

        prismaMock.card.findMany.mockResolvedValue(mockCards)

        const response = await request(app).get('/api/cards')

        expect(response.status).toBe(200)
        expect(response.body).toHaveLength(2)
        expect(response.body[0]).toHaveProperty('name', 'Bulbasaur')
        expect(response.body[0]).toHaveProperty('pokedexNumber', 1)
        expect(response.body[1]).toHaveProperty('name', 'Charmander')
    })

    it('should return empty array when no cards exist', async () => {
        prismaMock.card.findMany.mockResolvedValue([])

        const response = await request(app).get('/api/cards')

        expect(response.status).toBe(200)
        expect(response.body).toEqual([])
    })

    it('should return 500 on database error', async () => {
        prismaMock.card.findMany.mockRejectedValue(new Error('Database error'))

        const response = await request(app).get('/api/cards')

        expect(response.status).toBe(500)
        expect(response.body).toHaveProperty('error', 'Erreur serveur')
    })
})